"""Execute addon contracts and syntax using the client's Lua 5.1 language version."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
import os
import argparse

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument("--database-dir",type=Path,help="Generated synthetic addon directory for end-to-end loading")
parser.add_argument("--real-data",action="store_true",help="Validate an internal real-data package, allowing partial coverage")
parser.add_argument("--aggregate",action="store_true",help="Validate an aggregate package (large sampleCount, no mock notice)")
parser.add_argument("--single-file",type=Path,help="Validate a self-contained data file (loads for both APIs)")
parser.add_argument("--lazy-dir",type=Path,help="Validate a lazy GearData directory (core+sources+spec files)")
args=parser.parse_args()
os.chdir(ROOT)
paths=list(ROOT.rglob("*.lua"))
if args.database_dir:paths.extend(args.database_dir.rglob("*.lua"))
if args.single_file:paths.append(args.single_file)
if args.lazy_dir:paths.extend(args.lazy_dir.rglob("*.lua"))
for path in paths:
    if any(x in path.parts for x in ("archive","dist",".git")):continue
    runtime=LuaRuntime(unpack_returned_tuples=True)
    check=runtime.eval("function(text,name) local f,e=loadstring(text,name); if not f then error(e) end end")
    check(path.read_text(encoding="utf-8-sig"),str(path))
print("All workspace Lua files parse under Lua 5.1")
for locale in ("enUS","zhCN","zhTW","ruRU","deDE","frFR","esES","esMX","koKR","itIT","ptBR"):
    entry_runtime=LuaRuntime(unpack_returned_tuples=True)
    entry_run=entry_runtime.eval('assert(loadfile("tests/settings_entry_runtime.lua"))')
    entry_run(locale)
    stats_runtime=LuaRuntime(unpack_returned_tuples=True)
    stats_runtime.globals().GetLocale=lambda:locale
    stats_runtime.execute('''
        LibStub={GetLibrary=function() return {} end}
        function hooksecurefunc(name,fn) STATS_HOOK=name end
        assert(loadfile("InspectUnitStats.lua"))("InspectForEllesmereUI",{})
        assert(type(ShowInspectItemStatsFrame)=="function" and STATS_HOOK=="ShowInspectItemListFrame",
            "Equipment statistics must initialize for every client language")
    ''')
    for skin in (False,True):
        runtime=LuaRuntime(unpack_returned_tuples=True)
        if args.database_dir:
            runtime.globals().TEST_REAL_DATA=args.real_data
            runtime.globals().TEST_AGGREGATE_DATA=args.aggregate
            def read_addon(addon):
                filename="Core.lua" if addon in ("QFXGearData","QFXConsumableData") else "Data.lua"
                return (args.database_dir/addon/filename).read_text(encoding="utf-8-sig")
            runtime.globals().TEST_READ_ADDON=read_addon
        if args.single_file:
            runtime.globals().TEST_REAL_DATA=args.real_data
            runtime.globals().TEST_AGGREGATE_DATA=args.aggregate
            source=args.single_file.read_text(encoding="utf-8-sig")
            def read_single(addon):
                return source
            runtime.globals().TEST_READ_ADDON=read_single
        if args.lazy_dir:
            runtime.globals().TEST_REAL_DATA=args.real_data
            runtime.globals().TEST_AGGREGATE_DATA=args.aggregate
            combined="\n".join(p.read_text(encoding="utf-8-sig") for p in sorted(args.lazy_dir.glob("*.lua")))
            calls=[0]
            def read_lazy(addon):
                calls[0]+=1
                return combined if calls[0]==1 else ""
            runtime.globals().TEST_READ_ADDON=read_lazy
        run=runtime.eval('assert(loadfile("tests/recommendation_runtime.lua"))')
        run(locale,skin)
        display_runtime=LuaRuntime(unpack_returned_tuples=True)
        display_run=display_runtime.eval('assert(loadfile("tests/inspect_display_runtime.lua"))')
        display_run(locale,skin)
