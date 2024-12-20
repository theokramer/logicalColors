double calculateDifficulty(int maxMoves, int gridSize) {
  double difficulty = ((maxMoves * 3) / ((gridSize * gridSize) + 10)) *
      0.8; // Adjusting the multiplier to keep within 0 to 1 range
  return difficulty.clamp(0.0, 1.0);
}
