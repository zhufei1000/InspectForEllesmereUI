"""Verify TOC/XML dependency closure and cleanliness of loadable addon ZIPs."""
import argparse
from pathlib import Path
import posixpath
import zipfile
import xml.etree.ElementTree as ET


def verify(path):
    with zipfile.ZipFile(path) as archive:
        names=set(archive.namelist())
        assert len(names)==len(archive.namelist()),"Duplicate archive members"
        assert not any(x.lower().endswith((".md",".json",".py",".bak",".log")) for x in names)
        tocs=[x for x in names if x.endswith(".toc")]
        checked=set()
        def visit(name):
            assert name in names,"Missing dependency: "+name
            if name in checked:return
            checked.add(name)
            if name.endswith(".xml"):
                tree=ET.fromstring(archive.read(name))
                for node in tree.iter():
                    file=node.attrib.get("file")
                    if file:visit(posixpath.normpath(posixpath.join(posixpath.dirname(name),file.replace("\\","/"))))
        for toc in tocs:
            root=toc.split("/")[0]
            assert toc==root+"/"+root+".toc"
            for line in archive.read(toc).decode("utf-8-sig").splitlines():
                if line.strip() and not line.startswith("#"):
                    visit(posixpath.normpath(posixpath.join(root,line.strip().replace("\\","/"))))
        print(f"PASS {path.name}: {len(tocs)} addon roots, {len(names)} files; TOC/XML closure and clean payload")


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("packages",nargs="+",type=Path)
    for path in p.parse_args().packages:verify(path)
