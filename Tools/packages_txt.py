#!/usr/bin/env python3
"""Creates the packages.txt the editor turns into Data/Paths.bin and Data/PackagesPaths.bin.

A platform independent replacement for the "Package Hashlist Outputter" script of the DieselBundleViewer
(https://github.com/Luffyyy/DieselBundleViewer-Scripts), no Windows needed. Only the standard library is used.

    python3 packages_txt.py [--game-dir DIR] [--hashlist FILE] [--out FILE] [--compare OLD_PACKAGES_TXT]

The hashlist is taken from the official "RAID World War II Modding Tools" (Steam tool, data/hashlist),
it is expected next to the game in the steamapps/common folder. Pass --hashlist if it lives somewhere else.

Put the result in the BeardLib-Editor folder (the default of --out) and start the game, the editor
reads it on startup, writes the Data files and deletes it. Back up Data/ first, it is overwritten.

How it works
* assets/bundle_db.blb lists every file of the game (extension hash, path hash, id).
* every assets/<hash>_h.bundle is the header of a package, the file name is the hash of the package name.
  The header is zlib compressed and lists the ids of the files of that package.
* the names behind the hashes come from the hashlist, a package or file whose name is not in it is skipped.
"""
import argparse
import glob
import os
import struct
import sys
import zlib

MASK = (1 << 64) - 1


# Hash of the engine (Bob Jenkins' 64 bit hash), same as Idstring(...):key().
def _mix(a, b, c):
    a = (a - b - c) & MASK; a ^= c >> 43
    b = (b - c - a) & MASK; b ^= (a << 9) & MASK
    c = (c - a - b) & MASK; c ^= b >> 8
    a = (a - b - c) & MASK; a ^= c >> 38
    b = (b - c - a) & MASK; b ^= (a << 23) & MASK
    c = (c - a - b) & MASK; c ^= b >> 5
    a = (a - b - c) & MASK; a ^= c >> 35
    b = (b - c - a) & MASK; b ^= (a << 49) & MASK
    c = (c - a - b) & MASK; c ^= b >> 11
    a = (a - b - c) & MASK; a ^= c >> 12
    b = (b - c - a) & MASK; b ^= (a << 18) & MASK
    c = (c - a - b) & MASK; c ^= b >> 22
    return a, b, c


def hash64(text):
    data = text.encode("utf-8")
    length = len(data)
    a = b = 0
    c = 0x9e3779b97f4a7c13
    i = 0
    left = length
    while left >= 24:
        a = (a + int.from_bytes(data[i:i + 8], "little")) & MASK
        b = (b + int.from_bytes(data[i + 8:i + 16], "little")) & MASK
        c = (c + int.from_bytes(data[i + 16:i + 24], "little")) & MASK
        a, b, c = _mix(a, b, c)
        i += 24
        left -= 24
    c = (c + length) & MASK
    for j, byte in enumerate(data[i:]):
        if j < 8:
            a = (a + (byte << (8 * j))) & MASK
        elif j < 16:
            b = (b + (byte << (8 * (j - 8)))) & MASK
        else:
            c = (c + (byte << (8 * (j - 15)))) & MASK  # the first byte of c is reserved for the length
    return _mix(a, b, c)[2]


def load_hashlist(path):
    """hash -> string. Paths are lower case and lose everything after a ':' (like the bundle viewer does)."""
    hashes = {}
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            s = line.rstrip("\r\n")
            if not s or s.startswith("//"):
                continue
            if "/" in s:
                s = s.split(":", 1)[0].lower()
            hashes.setdefault(hash64(s), s)
    return hashes


def load_database(path):
    """id -> (extension hash, path hash) of assets/bundle_db.blb."""
    with open(path, "rb") as f:
        data = f.read()
    count = struct.unpack_from("<Q", data, 0x38)[0]
    offset = struct.unpack_from("<Q", data, 0x48)[0]
    entries = {}
    for i in range(count):
        ext, path_hash, _lang, _u1, entry_id, _u2 = struct.unpack_from("<QQIIII", data, offset + i * 32)
        entries.setdefault(entry_id, (ext, path_hash))
    return entries


def read_header(path):
    """Decompressed bytes of a package header (<hash>_h.bundle): u64 size, then chunks of u32 length + zlib data."""
    with open(path, "rb") as f:
        data = f.read()
    total = struct.unpack_from("<Q", data, 0)[0]
    pos = 8
    out = b""
    while pos + 4 <= len(data) and len(out) < total:
        size = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        out += zlib.decompress(data[pos:pos + size])
        pos += size
    return out[:total]


def header_ids(header):
    """Database ids of the files in a package header, None if the layout is unknown."""
    ref = struct.unpack_from("<I", header, 0)[0]
    base = 4
    if struct.unpack_from("<Q", header, 4)[0] == 0 and struct.unpack_from("<Q", header, 12)[0] != 0:
        base = 12  # variant with a length per entry, used by the stream_* bundles
    count = struct.unpack_from("<Q", header, base)[0]
    start = struct.unpack_from("<Q", header, base + 16)[0] + 4
    if count == 0:
        return []
    size = ref - start
    if size % count or size // count not in (8, 12):
        return None
    stride = size // count
    return [struct.unpack_from("<I", header, start + i * stride)[0] for i in range(count)]


def is_other_name(s):
    return not any(bad in s for bad in ("/", "PassThroughGP", "pln_", "achievement_", ":", "@", "."))


def build(assets_dir, hashlist_path):
    hashes = load_hashlist(hashlist_path)
    database = load_database(os.path.join(assets_dir, "bundle_db.blb"))
    lines = []
    unnamed = []
    for header_file in sorted(glob.glob(os.path.join(assets_dir, "*_h.bundle"))):
        bundle = os.path.basename(header_file)[:-len("_h.bundle")]
        if bundle.startswith("stream_"):
            name = bundle  # not hashed
        else:
            name = hashes.get(int.from_bytes(bytes.fromhex(bundle), "little"))
            if name is None:
                unnamed.append(bundle)
                continue
        ids = header_ids(read_header(header_file))
        if ids is None:
            print("[warning] unknown header layout, skipping " + bundle, file=sys.stderr)
            continue
        lines.append("@" + name)
        for entry_id in ids:
            if entry_id not in database:
                continue
            ext, path_hash = database[entry_id]
            path, ext_name = hashes.get(path_hash), hashes.get(ext)
            if path and ext_name:
                lines.append(path + "." + ext_name)
    lines.append("@other")
    lines.extend(s for s in hashes.values() if is_other_name(s))
    return lines, unnamed


def read_packages(path):
    packages = {}
    current = None
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.rstrip("\r\n")
            if line.startswith("@"):
                current = packages.setdefault(line[1:], set())
            elif current is not None and line:
                current.add(line)
    return packages


def compare(old_path, lines, out_path):
    old = read_packages(old_path)
    new = read_packages(out_path)
    changed = [name for name in old if name in new and old[name] != new[name]]
    print("compared to %s: %d packages (old) / %d (new), %d only in old, %d only in new, %d changed" % (
        old_path, len(old), len(new), len(set(old) - set(new)), len(set(new) - set(old)), len(changed)))
    print("  files removed: %d, added: %d" % (
        sum(len(old[n] - new[n]) for n in old if n in new), sum(len(new[n] - old[n]) for n in old if n in new)))


def main():
    mod_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    default_game = os.path.dirname(os.path.dirname(mod_dir))
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--game-dir", default=default_game, help="game folder (default: two levels above the mod)")
    parser.add_argument("--hashlist", help="hashlist (default: data/hashlist of the 'RAID World War II Modding Tools' next to the game)")
    parser.add_argument("--out", default=os.path.join(mod_dir, "packages.txt"), help="default: <mod>/packages.txt")
    parser.add_argument("--compare", help="an older packages.txt to print the differences to")
    args = parser.parse_args()

    hashlist = args.hashlist or os.path.join(os.path.dirname(os.path.abspath(args.game_dir)),
                                             "RAID World War II Modding Tools", "data", "hashlist")
    if not os.path.isfile(hashlist):
        parser.error("hashlist not found: %s (install the 'RAID World War II Modding Tools' from Steam or use --hashlist)" % hashlist)
    lines, unnamed = build(os.path.join(args.game_dir, "assets"), hashlist)
    with open(args.out, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print("wrote %s (%d lines), %d packages without a name in the hashlist" % (args.out, len(lines), len(unnamed)))
    if args.compare:
        compare(args.compare, lines, args.out)


if __name__ == "__main__":
    main()
