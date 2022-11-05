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
    global img
    global sx
    global sy
    global lines
    global objs
    mapdata = []
    filenames = []
    for filename in os.listdir("./rawmaps/"):
        if filename.endswith(".png") and filename != "template.png":
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
        mapdata.append([count/filenames.__len__(), filename, terrain, objs])
        count += 1
        #print(text)
    fwrite = open("./Cata/assets/json/vaults/town.json", "w+")
    fwrite.write(json.dumps(mapdata))
    fwrite.close()

def process():
    r = ""
    for y in range(sy):
        line = []
        for x in range(sx):
            cell = pixel_to_char((x, y))[0]
            line.append(cell)
        lines.append(line)
    return process_buildings()

def pixel_to_char(at):
    pixel = img.getpixel(at)
    cell = ' '
    if pixel[0] == pixel[1] == pixel[2]:
        if pixel[0] == 0:
            cell = ('H','H')
        elif pixel[0] == 48:
            cell = ('H','B')
        elif pixel[0] == 128:
            cell = ('_','_', 1)
        elif pixel[0] == 192:
            cell = ('_','_', 6)
    elif pixel == (0, 255, 255):
        cell = ('_','+', 2)
    elif pixel == (255, 216, 0):
        cell = ('=','=')
    elif pixel == (127, 51, 0):
        cell = ('_','_', 3)
    elif pixel == (127, 0, 0):
        cell = ('_',':', 4)
    elif pixel == (127, 106, 0):
        cell = ('_','_', 5)
    elif pixel == (185, 122, 87):
        cell = ('#','#')
    elif pixel == (0, 0, 255):
        cell = ('~','~')
    elif pixel == (72, 0, 255):
        cell = ('I','n')
        objs["n"] = [",", ["grave", 0.95]]
    elif pixel == (182, 255, 0):
        cell = (',',',')
    return cell

def process_buildings():
    r = ""
    walls = []
    room = []
    roomtiles = []
    doorfront = []
    for y in range(sy):
        line = ""
        for x in range(sx):
            cell = lines[y][x]
            adjs = get_neighbors_4(x, y)
            if cell == "H":
                wallnum = adjs.count("H")
                if wallnum == 2 and adjs.count(" ") == 1:
                    walls.append((x, y))
            elif cell == "=":
                for i in range(4):
                    offset = DIRS[i*2]
                    if adjs[i] == "_":
                        room.append((x + offset[0], y + offset[1]))
                    elif adjs[i] == " ":
                        doorfront.append((x + offset[0], y + offset[1]))
    for i in room:
        lines[i[1]][i[0]] = "O"
    for i in room:
        if lines[i[1]][i[0]] == "O":
            roomtiles.append(define_room(i[0], i[1], []))
    for roomtile in roomtiles:
        process_room(roomtile)
    for i in walls:
        walltile = pixel_to_char(i)[1]
        lines[i[1]][i[0]] = walltile
        if walltile == 'H' and random.randrange(0, 4) == 0:
            lines[i[1]][i[0]] = "-"
    generics = ('_', 'I', 'H')
    dictionary = {}
    dictionary_idx = 192
    for y in range(sy):
        for x in range(sx):
            cell = lines[y][x]
            if cell.__len__() > 1:
                if cell in dictionary:
                    lines[y][x] = dictionary[cell][0]
                else:
                    dictionary_idx += 1
                    lines[y][x] = chr(dictionary_idx)
                    dictionary[cell] = chr(dictionary_idx)
                    objs[chr(dictionary_idx)] = (pixel_to_char((x, y))[1], json.loads(cell))
            elif cell in generics:
                ptc = pixel_to_char((x, y))
                if ptc[0] == cell:
                    lines[y][x] = ptc[1]
    for i in doorfront:
        lines[i[1]][i[0]] = "."
    return lines

def process_room(roomtiles):
    fside = random.randrange(0, 2) * 2
    walled = []
    corner = []
    opened = []
    doorway = []
    edge = []
    x1 = 999
    x2 = -999
    y1 = 999
    y2 = -999
    for i in roomtiles:
        if i[0] < x1:
            x1 = i[0]
        if i[1] < y1:
            y1 = i[1]
        if i[0] > x2:
            x2 = i[0]
        if i[1] > y2:
            x1 = i[1]
        adjs = get_neighbors_4(i[0], i[1])
        floors = adjs.count("_")
        walls = adjs.count("H")
        if floors == 3 and walls == 1:
            if adjs[0+fside] == "H" or adjs[1+fside] == "H":
                walled.append(i)
        elif floors == 2 and walls == 2:
            if adjs[0] != adjs[2] or adjs[1] != adjs[3]:
                corner.append(i)
            else:
                doorway.append(i)
        elif walls == 3:
            edge.append(i)
        elif floors == 4:
            opened.append(i)
    for i in roomtiles:
        lines[i[1]][i[0]] = "_"
    for i in walled:
        if get_neighbors_in_array(DIRS, i[0], i[1], doorway, 0) == 0:
            adjs = get_neighbors_4(i[0], i[1])
            lines[i[1]][i[0]] = "*"
    for i in corner:
        if get_neighbors_in_array(DIRS, i[0], i[1], doorway, 0) == 0:
            if get_neighbors_in_array(CARDINALS, i[0], i[1], corner, 0) > 0:
                lines[i[1]][i[0]] = "*"
            else:
                adjs = get_neighbors_8(i[0], i[1])
                if adjs.count(pixel_to_char(i)[0]) == 3:
                    lines[i[1]][i[0]] = "*"
                else:
                    lines[i[1]][i[0]] = "*"
    for i in opened:
        if get_neighbors_in_array(DIRS, i[0], i[1], doorway, 0) == 0:
            if get_neighbors_in_array(DIRS, i[0], i[1], walled + corner, 0) == 0:
                lines[i[1]][i[0]] = "T"
    furnitures = {
        1: {
            "*": (["_","_","l"],("_","_","_","_","r","%","S","T","x")),
            "T": (["_","_","_","_","*","_","_","*"],("_","r","%","T","H","H","H","H")),
        },
        2: {
            "*": (["k","v","w"],("_")),
        },
        3: {
            "*": (["b","D","$","l","W"],("_")),
            "T": (["H"],("H")),
        },
        4: {
            "*": ([],("?","_","_","_")),
            "T": ([],("?","_","_","_","_","_")),
        },
        5: {
            "*": (["F","O","C","C","x"],("_","C","C","%","l","r")),
            "T": (["*","T"],("T","_")),
        },
        6: {
            "*": (["l","h"],("D","D","H","C","R","_")),
            "T": (["*"],("R","h","T","T","T","H","H","H","H",'["statue", 0.7]',"_","_","_","_","_","_","_","_","_","_","_","_")),
        },
    }
    for i in edge:
        adjs = get_neighbors_8(i[0], i[1])
        if adjs.count("H") >= 5:
            lines[i[1]][i[0]] = ["d","r","_"][random.randrange(0, 2)]
    for i in walled + corner + opened:
        cell = lines[i[1]][i[0]]
        furniture = furnitures[pixel_to_char(i)[2]]
        if cell in furniture:
            t = rarr(furniture[cell][0])
            if t is None:
                t = rarr(furniture[cell][1])
            else:
                furniture[cell][0].remove(t)
            lines[i[1]][i[0]] = t
            if t == "D" or t == "T": #put chairs
                direction = rarr(CARDINALS)
                offset = (i[0]+direction[0], i[1]+direction[1])
                if lines[offset[1]][offset[0]] == '_':
                    lines[offset[1]][offset[0]] = "c"

def get_neighbors_in_array(dirarr, x, y, arr, r):
    for i in dirarr:
        if (x+i[0], y+i[1]) in arr:
            r += 1
    return r

def define_room(x, y, tiles):
    if lines[y][x] == "O":
        lines[y][x] = "_"
    if lines[y][x] == "_" and (x, y) not in tiles:
        tiles.append((x, y))
        adjs = get_neighbors_4(x, y)
        for i in range(4):
            offset = DIRS[i*2]
            define_room(x+offset[0], y+offset[1], tiles)
    return tiles

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
