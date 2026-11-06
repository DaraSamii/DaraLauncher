"""frames/*.png -> demo.gif (one shared palette: small file, no colour flicker), screenshots -> docs/*.png (1600 px wide)."""
import glob, os, sys
from PIL import Image

out, docs = sys.argv[1], sys.argv[2]
frames = sorted(glob.glob(out + "/frames/f*.png"))
if not frames:
    sys.exit("no frames captured")
W = 880
imgs = []
for f in frames:
    im = Image.open(f).convert("RGB")
    imgs.append(im.resize((W, round(im.height * W / im.width)), Image.LANCZOS))
sample = imgs[::max(1, len(imgs) // 12)]
sheet = Image.new("RGB", (W, sum(i.height for i in sample)))
y = 0
for i in sample:
    sheet.paste(i, (0, y)); y += i.height
pal = sheet.quantize(colors=112, method=Image.Quantize.MEDIANCUT)
pimgs = [i.quantize(palette=pal, dither=Image.Dither.NONE) for i in imgs]
pimgs[0].save(docs + "/demo.gif", save_all=True, append_images=pimgs[1:], duration=125, loop=0, optimize=True, disposal=1)
print("demo.gif: %d frames, %.1f MB" % (len(pimgs), os.path.getsize(docs + "/demo.gif") / 1e6))
for f in glob.glob(out + "/*.png"):
    im = Image.open(f).convert("RGB")
    if im.width > 1600:
        im = im.resize((1600, round(im.height * 1600 / im.width)), Image.LANCZOS)
    im.save(docs + "/" + os.path.basename(f), optimize=True)
    print(os.path.basename(f), im.size)
