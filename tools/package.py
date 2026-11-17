#!/usr/bin/env python3
import hashlib, pathlib, zipfile, re
ROOT=pathlib.Path(__file__).resolve().parents[1]
RUNTIME=ROOT/'TitanCommandHistory'
def version():
 text=(RUNTIME/'TitanCommandHistory.toc').read_text()
 match=re.search(r'^## Version: ([0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?)$',text,re.M)
 if not match:raise ValueError('Invalid manifest version')
 value=match.group(1)
 if ("ns.version='"+value+"'") not in (RUNTIME/'Namespace.lua').read_text():raise ValueError('Runtime/manifest version mismatch')
 return value
def files():
 toc=RUNTIME/'TitanCommandHistory.toc'
 paths=[toc,RUNTIME/'Artwork/AddonIcon.tga']+[RUNTIME/l.strip() for l in toc.read_text().splitlines() if l.strip().endswith('.lua')]
 for p in paths:
  if not p.is_file() or not p.resolve().is_relative_to(RUNTIME.resolve()):raise ValueError('Invalid runtime path')
 return paths
if __name__=='__main__':
 out=ROOT/'dist';out.mkdir(exist_ok=True);target=out/('TitanCommandHistory-'+version()+'.zip')
 with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as z:
  for p in files():
   info=zipfile.ZipInfo(p.relative_to(ROOT).as_posix(),(2026,11,10,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o644<<16;z.writestr(info,p.read_bytes())
 (out/'SHA256SUMS').write_text(hashlib.sha256(target.read_bytes()).hexdigest()+'  '+target.name+'\n')
 print(target)
