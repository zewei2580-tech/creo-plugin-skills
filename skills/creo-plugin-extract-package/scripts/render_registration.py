"""Render the tested ASCII-path native DAT generator into an isolated stage."""
import argparse
import json
from pathlib import Path, PureWindowsPath
import re


def safe_name(value, label, pattern, limit):
    if not isinstance(value, str) or len(value) > limit or not re.fullmatch(pattern, value):
        raise ValueError(f"Invalid {label}: {value!r}")
    return value


def render(spec, stage, source):
    app = safe_name(spec['app_id'], 'app_id', r'[A-Za-z][A-Za-z0-9_]*', 30)
    folder = safe_name(spec.get('folder_name', app), 'folder_name', r'[A-Za-z][A-Za-z0-9_-]*', 60)
    dll = safe_name(spec['dll_name'], 'dll_name', r'[A-Za-z0-9_-]+\.dll', 100)
    version = safe_name(spec['version'], 'version', r'[A-Za-z0-9_.-]+', 20)
    required = [dll]
    for value in spec['required_files']:
        if not isinstance(value, str) or not value.isascii() or any(c in value for c in '\r\n\t"%<>|:*?'):
            raise ValueError(f'Invalid required file: {value!r}')
        path = PureWindowsPath(value)
        if path.is_absolute() or path.drive or path.root or '..' in path.parts or not path.parts:
            raise ValueError(f'Required file must stay inside stage: {value!r}')
        relative = str(path)
        if relative not in required:
            required.append(relative)
    stage = Path(stage).resolve()
    for relative in required:
        target = stage.joinpath(*PureWindowsPath(relative).parts).resolve()
        if not target.is_relative_to(stage) or not target.is_file():
            raise ValueError(f'Missing or external required file: {relative}')
    template = Path(__file__).resolve().parents[1] / 'assets/generate_dat.c.in'
    code = template.read_text(encoding='utf-8-sig')
    values = {'APP_ID': app, 'FOLDER_NAME': folder, 'DLL_NAME': dll, 'VERSION': version,
              'REQUIRED_FILES': ',\n  '.join('L' + json.dumps(s) for s in required)}
    for key, value in values.items():
        code = code.replace('@@' + key + '@@', value)
    if re.search(r'@@[A-Z_]+@@', code):
        raise ValueError('Unresolved generator template field')
    root = 'C:\\' + folder
    dat = '\n'.join([f'name {app}', f'description {app} {version}', 'toolkit OBJECT',
                     'creo_type PARAMETRIC', 'startup dll', f'exec_file {root}\\{dll}',
                     f'text_dir {root}\\text', 'allow_stop true', 'delay_start false', 'end', ''])
    source = Path(source)
    source.parent.mkdir(parents=True, exist_ok=True)
    source.write_text(code, encoding='utf-8', newline='\n')
    (stage / 'protk.dat').write_text(dat, encoding='ascii', newline='\r\n')
    return required


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('spec', type=Path)
    parser.add_argument('--stage', type=Path, required=True)
    parser.add_argument('--source', type=Path, required=True)
    args = parser.parse_args()
    files = render(json.loads(args.spec.read_text(encoding='utf-8-sig')), args.stage, args.source)
    print(f'Generated DAT and C source; validated {len(files)} required files.')
