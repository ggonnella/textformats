__switches__ = {
    'import' : [
        'nimble',
        'c',
        '--app:lib',
        '-d:danger',
        '--gc:mark_and_sweep',
        f'--out:{BUILD_ARTIFACT}',
        f'{MODULE_PATH}'
    ],
    'bundle' : [
        'nimble' if IS_LIBRARY else 'nim',
        'cc',
        '-c',
        '--accept',
        '-d:danger',
        '--gc:mark_and_sweep',
        f'--nimcache:{BUILD_DIR}',
        f'{MODULE_PATH}'
    ]
}

