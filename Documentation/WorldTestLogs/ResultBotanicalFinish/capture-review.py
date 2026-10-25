from pathlib import Path
import os, subprocess, time
sim = 'B456A1D8-46EB-4049-A5A8-371C089E6C98'
out = Path('Documentation/Screenshots/ResultBotanicalFinish/review'); out.mkdir(parents=True, exist_ok=True)
with Path('Documentation/WorldTestLogs/ResultBotanicalFinish/review.log').open('w') as log:
    subprocess.run(['xcrun', 'simctl', 'install', sim, '/tmp/dino-botanical-finish-build/Build/Products/Debug-iphonesimulator/Dino Time.app'], stdout=log, stderr=log, check=True)
    for world, level in [(1, 8), (4, 32), (7, 62)]:
        env = os.environ.copy()
        env.update({'SIMCTL_CHILD_DINO_TEST_SUITE': f'dino.botanical.review.{world}', 'SIMCTL_CHILD_DINO_TEST_RESULT_LEVEL': str(level), 'SIMCTL_CHILD_DINO_TEST_RESULT_CORRECT': '5', 'SIMCTL_CHILD_DINO_TEST_COMPLETED_LEVEL': str(level - 1)})
        subprocess.run(['xcrun', 'simctl', 'launch', '--terminate-running-process', sim, 'Hakketjak.Dino-Klokkijken', '-settings.languageOverride', 'en'], env=env, stdout=log, stderr=log, check=True)
        time.sleep(6)
        subprocess.run(['xcrun', 'simctl', 'io', sim, 'screenshot', str(out / f'world-{world:02}.png')], stdout=log, stderr=log, check=True)
