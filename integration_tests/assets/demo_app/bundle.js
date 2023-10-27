const counterContainer = document.querySelector('#counter');
let start = 0;
setInterval(() => {
  counterContainer.textContent = start++;
  counterContainer.style.backgroundColor = generateColorByCount(start);
}, 500);

function generateColorByCount(count) {
  // 'count' is the unique identifier for each color. It could be an index, timestamp, etc.
  // Choose a range for the hue (0-360), keeping saturation and lightness constant.

  const hue = count * 137.508; // use golden angle approximation
  const saturation = 75;
  const lightness = 60;

  // Ensure the hue falls within the range 0-360.
  const adjustedHue = hue % 360;

  return `hsl(${adjustedHue}, ${saturation}%, ${lightness}%)`;
}
