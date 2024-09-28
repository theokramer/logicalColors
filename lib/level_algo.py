import random
import json
import os


class Level:
    def __init__(self, worldNr, levelNr, size, clicks):
        self.worldNr = worldNr
        self.levelNr = levelNr
        self.size = size
        self.clicks = clicks


def levelAlgo(gridSize, moves, worldNr, levelNr):
    clicks = []
    for i in range(moves):
        x = random.randint(0, gridSize - 1)
        y = random.randint(0, gridSize - 1)
        clicks.append({"x": x, "y": y})  # Klicks als Dictionary speichern

    return Level(worldNr, levelNr, gridSize, clicks)


def save_level_to_file(level, filename="levels.json"):
    # Prüfen, ob die Datei existiert
    if os.path.exists(filename):
        # Vorhandene Levels laden
        with open(filename, "r") as f:
            levels = json.load(f)
    else:
        levels = []

    # Neues Level zur Liste hinzufügen
    levels.append(level.__dict__)

    # Liste wieder in die Datei schreiben
    with open(filename, "w") as f:
        json.dump(levels, f, indent=5)

def generateLevel(worldNr, levelNr):
    level = levelNr
    if level == 1:
        s = 1
        m = 1
    elif level in (2, 3):
        s = 2
        m = 1
    elif level in (4, 5, 6):
        s = 2
        m = 2
    elif level in (7, 8):
        s = 2
        m = 3
    elif level == 9:
        s = 3
        m = 1
    elif level == 10:
        s = 3
        m = 2
    elif level == 11:
        s = 3
        m = 3
    elif level == 12:
        s = 3
        m = 4
    elif level == 13:
        s = 3
        m = 4
    elif level == 14:
        s = 3
        m = 4
    elif level == 15:
        s = 4
        m = 1
    elif level == 16:
        s = 4
        m = 3
    elif level == 17:
        s = 4
        m = 4
    elif level == 18:
        s = 4
        m = 4
    else:
        s = 2
        m = 3

    return levelAlgo(s, m, worldNr, levelNr)


if __name__ == '__main__':
    # Level generieren und speichern
    for i in range(15):
        level1 = generateLevel(1, i + 1)
        save_level_to_file(level1)
