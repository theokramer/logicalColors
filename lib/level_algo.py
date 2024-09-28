import random
import json
import os


class Level:
    def __init__(self, worldNr, levelNr, clicks):
        self.worldNr = worldNr
        self.levelNr = levelNr
        self.clicks = clicks


def levelAlgo(gridSize, moves, worldNr, levelNr):
    clicks = []
    for i in range(moves):
        x = random.randint(0, gridSize - 1)
        y = random.randint(0, gridSize - 1)
        clicks.append({"x": x, "y": y})  # Klicks als Dictionary speichern

    return Level(worldNr, levelNr, clicks)


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


if __name__ == '__main__':
    # Level generieren und speichern
    level1 = levelAlgo(2, 1, 1, 2)
    save_level_to_file(level1)

    level2 = levelAlgo(2, 2, 1, 3)
    save_level_to_file(level2)

    print(level2.clicks)
