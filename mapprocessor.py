import json
import os
import sys
import re
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops, ImageEnhance

DIRS = ((0,-1),(1,-1),(1,0),(1,1),(0,1),(-1,1),(-1,0),(-1,-1))
CARDINALS = ((0,-1),(1,0),(0,1),(-1,0))
lines = []
img = None
objs = {}
sx = 1
sy = 1

def run(args):
    run_file(args+"_s")
    run_file(args+"_c")
    run_file(args+"_f")

def run_file(args):
    global img
    global sx
    global sy
    global lines
    global objs
    mapdata = []
    filenames = []
    for filename in os.listdir("./rawmaps/"):
        if filename.startswith(args) and filename.endswith(".png") and filename != "template.png":
            filenames.append(filename)
    count = 1
    for filename in filenames:
        lines = []
        objs = {}
        img = Image.open("./rawmaps/"+filename).convert('RGB')
        sx, sy = img.size
        process()
        text = ""
        terrain = []
        for line in lines:
            row = ""
            for cell in line:
                row += cell
            terrain.append(row)
            text += row + "\n"
        mapdata.append([count/filenames.__len__(), filename[:-4], terrain, objs])
        count += 1
        #print(text)
    fwrite = open("./Crawler/assets/json/vaults/"+args+".json", "w+")
    fwrite.write(json.dumps(mapdata))
    fwrite.close()

def process():
    for y in range(sy):
        line = []
        for x in range(sx):
            cell = pixel_to_char((x, y))
            line.append(cell)
        lines.append(line)
    process_furniture()
    return lines

def pixel_to_char(at):
    pixel = img.getpixel(at)
    cell = ' '
    if pixel[0] == pixel[1] == pixel[2]:
        if pixel[0] == 0:
            cell = 'X'
        elif pixel[0] == 48:
            cell = 'H'
        elif pixel[0] == 128:
            cell = '*'
    elif pixel == (185, 122, 87):
        cell = '.'
    elif pixel == (0, 38, 255):
        cell = '~'
    elif pixel == (255, 106, 0):
        cell = 'v'
    elif pixel == (255, 216, 0):
        cell = '?'
    elif pixel == (126, 66, 255):
        cell = 'I'
    elif pixel == (127, 0, 0):
        cell = '@'
    return cell

def process_furniture():
    for y in range(1, sy-1):
        for x in range(1, sx-1):
            adjs = get_neighbors_4(x, y)
            if lines[y][x] == "*":
                if adjs.count("X") == 2:
                    if (adjs[0] == "X" and adjs[2] == "X") or (adjs[1] == "X" and adjs[3] == "X"):
                        lines[y][x] = "="

def get_neighbors_in_array(dirarr, x, y, arr, r):
    for i in dirarr:
        if (x+i[0], y+i[1]) in arr:
            r += 1
    return r

def get_neighbors_4(x, y):
    r = [None, None, None, None]
    if y > 0:
        r[0] = lines[y-1][x]
    if x < sx-1:
        r[1] = lines[y][x+1]
    if y < sy-1:
        r[2] = lines[y+1][x]
    if x > 0:
        r[3] = lines[y][x-1]
    return r


def get_neighbors_8(x, y):
    r = [None, None, None, None, None, None, None, None]
    if y > 0:
        r[0] = lines[y-1][x]
        if x < sx-1:
            r[1] = lines[y-1][x+1]
    if x < sx-1:
        r[2] = lines[y][x+1]
        if y < sy-1:
            r[3] = lines[y+1][x+1]
    if y < sy-1:
        r[4] = lines[y+1][x]
        if x > 0:
            r[5] = lines[y+1][x-1]
    if x > 0:
        r[6] = lines[y][x-1]
        if y > 0:
            r[7] = lines[y-1][x-1]
    return r

def rarr(arr):
    size = arr.__len__()
    if size == 0:
        return None
    elif size == 1:
        return arr[0]
    return arr[random.randrange(0, size-1)]

if __name__ == "__main__":
    if sys.argv.__len__() > 1:
        run(sys.argv[1])
    else:
        run(None)
