#!/usr/bin/env python3
import argparse, pathlib, shutil, tempfile, time
from package import RUNTIME, files
p=argparse.ArgumentParser();p.add_argument('--addons-dir',type=pathlib.Path,required=True);p.add_argument('--apply',action='store_true');a=p.parse_args()
base=a.addons_dir.resolve();target=base/'TitanCommandHistory'
if not base.is_dir():raise SystemExit('AddOns directory missing')
if target.is_symlink():raise SystemExit('Refusing symlink destination')
paths=files();print(f'{len(paths)} runtime files -> {target}')
if not a.apply:print('Preview only; add --apply to install.');raise SystemExit(0)
backup=None
with tempfile.TemporaryDirectory(prefix='.tch-install-',dir=base) as temp:
 stage=pathlib.Path(temp)/'TitanCommandHistory';stage.mkdir()
 for source in paths:
  relative=source.relative_to(RUNTIME);dest=stage/relative;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dest)
 if target.exists():
  backup=base/('.TitanCommandHistory-backup-'+str(time.time_ns()));target.rename(backup)
 try:
  stage.rename(target)
  for source in paths:
   if (target/source.relative_to(RUNTIME)).read_bytes()!=source.read_bytes():raise RuntimeError('Installed byte mismatch')
 except Exception:
  if target.exists():shutil.rmtree(target)
  if backup:backup.rename(target)
  raise
 print('Installed and verified. Backup: '+str(backup))
