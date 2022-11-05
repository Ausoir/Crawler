from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops, ImageEnhance
coord_mapping = (
    ("single", "left", "h", "right", "top", "topleft", "midtop", "topright"),
    ("topleft", "topright", "midleft", "midtop", "v", "midleft", "all", "midright"),
    ("bottomleft", "bottomright", "midbottom", "midright", "bottom", "bottomleft", "midbottom", "bottomright"),
    ("midleft", "midright", "midtop", "midtop", "all", "all", "all", "all"),
    ("midleft", "midright", "midbottom", "midbottom", "all", "all", "all", "all"),
    ("all", "all", "all", "all", "all", "all", "all", "all"),
)

def run():
    make_autotile_8('./autotiles/', 't_rock_smooth_')

def make_autotile_8(filedir, prefix):
    tiles = ['unconnected', 'end_piece_w', 'edge_ew', 'end_piece_e',
            'end_piece_n', 'corner_nw', 't_connection_n', 'corner_ne',
            'edge_ns', 't_connection_w', 'center', 't_connection_e',
            'end_piece_s', 'corner_sw', 't_connection_s', 'corner_se']
    out = combine_tiles(filedir, prefix, tiles, 32, (4, 4))
    out.save(filedir + 'autotile.png', 'PNG')
    #out.show()

def combine_tiles(filedir, prefix, tilenames, tilesize, sizes):
    out = Image.new("RGBA", (tilesize*sizes[0], tilesize*sizes[1]), (255, 255, 255, 0))
    fromx = 0
    fromy = 0
    for i in tilenames:
        tile = Image.open(filedir+prefix+i+'.png').convert('RGBA')
        out.paste(tile, (fromx*tilesize, fromy*tilesize))
        fromx += 1
        if fromx >= sizes[0]:
            fromx = 0
            fromy += 1
    return out

def make_blendmap():
    east = Image.open('shadow_east.png').convert('RGBA')
    easttop = Image.open('shadow_east_top.png').convert('RGBA')
    northeast = Image.open('shadow_northeast.png').convert('RGBA')
    north = Image.open('shadow_north.png').convert('RGBA')
    northwest = Image.open('shadow_northwest.png').convert('RGBA')
    west = Image.open('shadow_west.png').convert('RGBA')
    westtop = Image.open('shadow_west_top.png').convert('RGBA')
    out = Image.new('RGBA', (160, 96), color=0)
    out.paste(west, (0, 0))
    out.paste(northwest, (32, 0))
    out.paste(north, (64, 0))
    out.paste(northeast, (96, 0))
    out.paste(east, (128, 0))
    out.paste(combine(west, north), (0, 32))
    out.paste(combine(east, north), (32, 32))
    out.paste(combine(east, west), (64, 32))
    out.paste(combine(northeast, west), (96, 32))
    out.paste(combine(northwest, east), (128, 32))
    out.paste(combine(combine(east, north),west), (0, 64))
    out.paste(westtop, (32, 64))
    out.paste(easttop, (64, 64))
    return out

def combine(p1, p2):
    out = p1.copy()
    sx, sy = out.size
    for x in range(sx):
        for y in range(sy):
            pixel1 = out.getpixel((x, y))
            pixel2 = p2.getpixel((x, y))
            color = (min(pixel1[0], pixel2[0]), min(pixel1[1], pixel2[1]), min(pixel1[2], pixel2[2]), max(pixel1[3], pixel2[3]))
            out.putpixel((x, y), color)
    return out

def make_gradient_tileset():
    img = Image.new('RGBA', (64, 64), color=0xFFFFFF)
    h = img
    v = img
    image_mapping = {}
    image_mapping["midleft"] = apply_gradient(v, 'L', 2)
    image_mapping["midright"] = apply_gradient(v, 'R', 2)
    image_mapping["midtop"] = apply_gradient(v, 'U', 2)
    image_mapping["midbottom"] = apply_gradient(h, 'D', 2)
    image_mapping["topleft"] = apply_gradient(image_mapping["midtop"], 'L', 2)
    image_mapping["topright"] = apply_gradient(image_mapping["midtop"], 'R', 2)
    image_mapping["bottomleft"] = apply_gradient(image_mapping["midbottom"], 'L', 2)
    image_mapping["bottomright"] = apply_gradient(image_mapping["midbottom"], 'R', 2)
    image_mapping["h"] = apply_gradient(image_mapping["midbottom"], 'U', 2)
    image_mapping["v"] = apply_gradient(image_mapping["midleft"], 'R', 2)
    image_mapping["left"] = apply_gradient(image_mapping["h"], 'L', 2)
    image_mapping["right"] = apply_gradient(image_mapping["h"], 'R', 2)
    image_mapping["top"] = apply_gradient(image_mapping["v"], 'U', 2)
    image_mapping["bottom"] = apply_gradient(image_mapping["bottomleft"], 'R', 2)
    image_mapping["single"] = apply_gradient(image_mapping["top"], 'D', 2)
    image_mapping["all"] = v
    return glassify(invert(finish_make(image_mapping, 64)),120)

def make_topdown_tileset(dir_in):
    img = Image.open(dir_in).convert('RGBA').resize((64, 64))
    h = make_tile_h(img)
    v = make_tile_v(img)
    image_mapping = {}
    image_mapping["midleft"] = apply_gradient(v, 'L', 1)
    image_mapping["midright"] = apply_gradient(v, 'R', 1)
    image_mapping["midtop"] = apply_gradient(v, 'U', 1)
    image_mapping["midbottom"] = apply_gradient(h, 'D', 1)
    image_mapping["topleft"] = apply_gradient(image_mapping["midtop"], 'L', 1)
    image_mapping["topright"] = apply_gradient(image_mapping["midtop"], 'R', 1)
    image_mapping["bottomleft"] = apply_gradient(image_mapping["midbottom"], 'L', 1)
    image_mapping["bottomright"] = apply_gradient(image_mapping["midbottom"], 'R', 1)
    image_mapping["h"] = apply_gradient(image_mapping["midbottom"], 'U', 1)
    image_mapping["v"] = apply_gradient(image_mapping["midleft"], 'R', 1)
    image_mapping["left"] = apply_gradient(image_mapping["h"], 'L', 1)
    image_mapping["right"] = apply_gradient(image_mapping["h"], 'R', 1)
    image_mapping["top"] = apply_gradient(image_mapping["v"], 'U', 1)
    image_mapping["bottom"] = apply_gradient(image_mapping["bottomleft"], 'R', 1)
    image_mapping["single"] = apply_gradient(image_mapping["top"], 'D', 1)
    image_mapping["all"] = v
    return finish_make(image_mapping, 64)

def finish_make(image_mapping, size):
    out = Image.new('RGBA', (size*8, size*6), color=0)
    y = 0
    for subimg_row in coord_mapping:
        x = 0
        for subimg in subimg_row:
            out.paste(image_mapping[subimg], (x, y))
            x += size
        y += size
    out = out.convert('RGBA')
    out = out.filter(ImageFilter.SHARPEN)
    return out


def make_tile_v(img):
    out = img
    half = img.resize((64, 32))
    out.paste(half, (0, 0))
    out.paste(half, (0, 32))
    enh = ImageEnhance.Brightness(out)
    out = enh.enhance(.8).transpose(Image.FLIP_LEFT_RIGHT)
    enh = ImageEnhance.Contrast(out)
    out = enh.enhance(.8)
    return out

def make_tile_h(img):
    out = img.resize((64, 64))
    upper = make_tile_v(out).crop((0, 0, 64, 32))
    lower = img.crop((2,8,62,56)).resize((64, 32))

    out.paste(upper, (0, 0))
    out.paste(lower, (0, 32))
    return out

def make_tileable(img):
    img = img.resize((66, 66))
    return img.crop((1, 1, 65, 65))

def apply_gradient(img, side, mode):
    if side == 'L':
        vertical = False
        flip = False
    elif side == 'R':
        vertical = False
        flip = True
    elif side == 'U':
        vertical = True
        flip = False
    elif side == 'D':
        vertical = True
        flip = True
    if vertical:
        gradient = Image.new('L', (1, 64), color=0)
        gradient_outline(gradient, mode, (0, 1))
        if flip:
            gradient = gradient.transpose(Image.FLIP_TOP_BOTTOM)
    else:
        gradient = Image.new('L', (64, 1), color=0)
        gradient_outline(gradient, mode, (1, 0))
        if flip:
            gradient = gradient.transpose(Image.FLIP_LEFT_RIGHT)
    alpha = gradient.resize((64, 64))
    black_im = Image.new('RGBA', (64, 64), color=0) # i.e. black
    black_im.putalpha(alpha)
    out = img.resize((64, 64))
    gradient_im = Image.alpha_composite(out, black_im)
    return gradient_im

def gradient_outline(gradient, mode, orientation):
    if mode == 1:
        for i in range(8):
            pixel = (i*orientation[0], i*orientation[1])
            if i == 0:
                gradient.putpixel(pixel, 100)
            elif i == 1:
                gradient.putpixel(pixel, 70)
            else:
                gradient.putpixel(pixel, 64-i*8)
    elif mode == 2:
        ratio = 255 / 4096
        for i in range(64):
            pixel = (i*orientation[0], i*orientation[1])
            gradient.putpixel(pixel, 255-int(i*i * ratio))

def carve(img):
    pixels = img.load()
    for x in range(img.size[0]):
        for y in range(img.size[1]):
            pixel = img.getpixel((x, y))
            pixels[x, y] = (0, 0, 0, pixel[0])
    return img

def invert(img):
    sx, sy = img.size
    out = img.copy()
    for x in range(sx):
        for y in range(sy):
            pixel = out.getpixel((x, y))
            out.putpixel((x, y), (pixel[0],pixel[1],pixel[2],255-pixel[3]))
    return out

def glassify(img):
    sx, sy = img.size
    out = Image.new('RGBA', (sx, sy), color=0)
    for x in range(sx):
        for y in range(sy):
            pixel = img.getpixel((x, y))
            out.putpixel((x, y), (pixel[0],pixel[1],pixel[2],125))
    return out

run()
