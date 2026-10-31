#!/usr/bin/env python3
"""Build/clone independent full-screen Gecko-Webpage IPAs from Reynard 0.19.0."""
import argparse
import hashlib
import io
import json
import plistlib
import re
import shutil
import struct
import zipfile
from pathlib import Path
from urllib.parse import urlparse

ORIGINAL_ID = "com.minh-ton.Reynard"
INJECT_PATH = "@executable_path/Frameworks/GeckoKiosk.dylib"
APP = "Payload/Reynard.app/"

def inject_load_command(contents: bytes) -> bytes:
    data = bytearray(contents)
    if struct.unpack_from("<I", data)[0] != 0xfeedfacf:
        raise ValueError("Expected a 64-bit ARM Mach-O executable")
    count, used = struct.unpack_from("<II", data, 16)
    pos = 32
    first_section = len(data)
    for _ in range(count):
        cmd, size = struct.unpack_from("<II", data, pos)
        if cmd == 0x19:
            num_sections = struct.unpack_from("<I", data, pos + 64)[0]
            for j in range(num_sections):
                section_offset = struct.unpack_from("<I", data, pos + 72 + 80*j + 48)[0]
                if section_offset:
                    first_section = min(first_section, section_offset)
        if cmd in (0xC, 0xD, 0x18, 0x1F):
            str_offset = struct.unpack_from("<I", data, pos + 8)[0]
            if bytes(data[pos + str_offset:pos + size]).split(b"\x00")[0] == INJECT_PATH.encode():
                return contents
        pos += size
    if pos != 32 + used:
        raise ValueError("Malformed Mach-O load commands")
    name = INJECT_PATH.encode() + b"\x00"
    command_size = (24 + len(name) + 7) & ~7
    if pos + command_size > first_section:
        raise ValueError("Insufficient executable-header padding to add runtime")
    command = struct.pack("<IIIIII", 0xC, command_size, 24, 0, 0, 0) + name
    data[pos:pos + command_size] = command.ljust(command_size, b"\x00")
    struct.pack_into("<II", data, 16, count + 1, used + command_size)
    return bytes(data)

def icons(custom_icon: Path | None) -> dict[str, bytes]:
    from PIL import Image, ImageDraw
    result = {}
    for dimension, suffix in [(120,"60x60@2x"),(180,"60x60@3x"),
                               (152,"76x76@2x"),(167,"83.5x83.5@2x")]:
        if custom_icon:
            src = Image.open(custom_icon).convert("RGB")
            w,h = src.size
            z = min(w,h)
            img = src.crop(((w-z)//2,(h-z)//2,(w+z)//2,(h+z)//2)).resize(
                (dimension,dimension),Image.Resampling.LANCZOS)
        else:
            img = Image.new("RGB",(dimension,dimension),"#1579D0")
            dr = ImageDraw.Draw(img)
            m=dimension/180
            dr.ellipse((30*m,30*m,150*m,150*m),outline="#65CCFA",width=max(2,round(16*m)))
            dr.arc((55*m,55*m,125*m,125*m),45,315,fill="white",width=max(2,round(15*m)))
            dr.line((99*m,90*m,143*m,90*m),fill="white",width=max(2,round(14*m)))
        buf=io.BytesIO()
        img.save(buf,"PNG",optimize=True)
        result[f"GeckoIcon{suffix}.png"]=buf.getvalue()
    return result

def optional_resource(path: str) -> bool:
    if not path.startswith(APP):
        return False
    sub = path[len(APP):]
    language = sub.split("/",1)[0]
    if language.endswith(".lproj") and language not in ("en.lproj","en-GB.lproj","Base.lproj"):
        return True
    prefix="Frameworks/GeckoView.framework/Frameworks/hyphenation/"
    if sub.startswith(prefix) and sub.endswith(".hyf"):
        return not sub[len(prefix):].lower().startswith(("hyph_en","hyph_und"))
    return False

def replace_plist(raw: bytes, bundle_id: str, app_name: str) -> bytes:
    obj = plistlib.loads(raw)
    def rewrite(value):
        if isinstance(value,dict):
            return {k:rewrite(v) for k,v in value.items()}
        if isinstance(value,list):
            return [rewrite(v) for v in value]
        if isinstance(value,str):
            return value.replace(ORIGINAL_ID,bundle_id)
        return value
    obj = rewrite(obj)
    if obj.get("CFBundlePackageType") == "APPL":
        obj["CFBundleDisplayName"] = app_name[:30]
        obj["CFBundleName"] = app_name[:30]
        for key,prefix in (("CFBundleIcons","60x60"),("CFBundleIcons~ipad","76x76")):
            obj[key]={"CFBundlePrimaryIcon":{"CFBundleIconFiles":[f"GeckoIcon{prefix}"]}}
        obj["CFBundleURLTypes"]=[{"CFBundleURLName":bundle_id,"CFBundleURLSchemes":["gek-"+bundle_id[-6:]]}]
        obj["UIStatusBarHidden"]=True
        obj["UIViewControllerBasedStatusBarAppearance"]=True
        obj["UIRequiresFullScreen"]=True
        obj["UIApplicationShortcutItems"]=[
            {"UIApplicationShortcutItemType":"com.551uk.gecko.website",
             "UIApplicationShortcutItemTitle":"Change Website",
             "UIApplicationShortcutItemIconType":"UIApplicationShortcutIconTypeCompose"},
            {"UIApplicationShortcutItemType":"com.551uk.gecko.fresh",
             "UIApplicationShortcutItemTitle":"Start New Session",
             "UIApplicationShortcutItemIconType":"UIApplicationShortcutIconTypeShuffle"},
        ]
    return plistlib.dumps(obj,fmt=plistlib.FMT_BINARY,sort_keys=False)

def main() -> None:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("--ipa",type=Path,required=True,help="Original Reynard 0.19.0 jailbroken IPA")
    p.add_argument("--dylib",type=Path,required=True,help="Compiled arm64 GeckoKiosk.dylib")
    p.add_argument("--url",default="https://google.com")
    p.add_argument("--name",default="Gecko WebApp")
    p.add_argument("--icon",type=Path,help="Optional custom PNG/JPEG icon")
    p.add_argument("--id",help="Unique six-character lowercase suffix")
    p.add_argument("--output",type=Path,required=True)
    p.add_argument("--no-slim",action="store_true",help="Retain all optional translation/hyphenation assets")
    args=p.parse_args()
    u=urlparse(args.url)
    if u.scheme not in ("http","https") or not u.hostname:
        p.error("URL must start with http:// or https:// and include a hostname")
    suffix=args.id or hashlib.sha256((args.url+"\x00"+args.name).encode()).hexdigest()[:6]
    if not re.fullmatch("[a-z0-9]{6}",suffix):
        p.error("--id must contain exactly six lowercase letters/numbers")
    bundle_id="com.551uk.gwa."+suffix
    assert len(bundle_id)==len(ORIGINAL_ID)
    dylib=args.dylib.read_bytes()
    if struct.unpack_from("<I",dylib)[0]!=0xfeedfacf or struct.unpack_from("<I",dylib,12)[0]!=6:
        p.error("The dylib must be a 64-bit iOS ARM64 Mach-O")
    assets={
       APP+"GeckoSite.json":json.dumps({"homepage":args.url,"websiteApp":True,"version":4}).encode(),
       APP+"Frameworks/GeckoKiosk.dylib":dylib,
    }
    for filename,data in icons(args.icon).items():
        assets[APP+filename]=data
    binaries={APP+"Reynard",APP+"PlugIns/OpenIn.appex/OpenIn",
              APP+"PlugIns/Reynard Helper.appex/Reynard Helper"}
    with zipfile.ZipFile(args.ipa) as zin, zipfile.ZipFile(
        args.output,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=6,allowZip64=True
    ) as zout:
        for info in zin.infolist():
            path=info.filename
            if ("/_CodeSignature/" in path or "embedded.mobileprovision" in path
                    or path in assets or (not args.no_slim and optional_resource(path))):
                continue
            new_info=zipfile.ZipInfo(path,info.date_time)
            new_info.compress_type=zipfile.ZIP_STORED if info.is_dir() else zipfile.ZIP_DEFLATED
            new_info.external_attr=info.external_attr
            new_info.create_system=info.create_system
            if info.is_dir():
                zout.writestr(new_info,b"")
            elif path.startswith(APP) and path.endswith("/Info.plist"):
                zout.writestr(new_info,replace_plist(zin.read(info),bundle_id,args.name))
            elif path in binaries:
                executable=zin.read(info).replace(ORIGINAL_ID.encode(),bundle_id.encode())
                if path == APP+"Reynard":
                    executable=inject_load_command(executable)
                zout.writestr(new_info,executable)
            else:
                with zin.open(info) as source, zout.open(new_info,"w",force_zip64=True) as output:
                    shutil.copyfileobj(source,output,length=1024*1024)
        for path,data in assets.items():
            zout.writestr(path,data,compress_type=zipfile.ZIP_DEFLATED)
    print(f"Created {args.output}, {args.output.stat().st_size:,} bytes, bundle ID {bundle_id}")
    print("UNSIGNED experimental IPA: use a compatible TrollStore installation")

if __name__=="__main__":
    main()
