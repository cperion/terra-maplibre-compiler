// Main host entry point

import Host from './host.js';

export { Host };

/**
 * Creates and initializes a Terra Map instance.
 *
 * @param {string} wasmPath - Path to the compiled .wasm map module.
 * @param {Object} options - Configuration options.
 * @param {HTMLCanvasElement|string} options.canvas - Canvas element or selector string.
 * @param {Object} [options.initialViewport] - Optional initial dimensions.
 * @param {number} options.initialViewport.width - Initial width.
 * @param {number} options.initialViewport.height - Initial height.
 * @returns {Promise<Host>} - A promise that resolves to the initialized Host instance.
 *
 * @example
 * import { createMapModule } from './index.js';
 *
 * try {
 *   const map = await createMapModule('maps/london.wasm', {
 *     canvas: '#map-canvas'
 *   });
 *   console.log('Map loaded!');
 * } catch (err) {
 *   console.error('Failed to load map:', err);
 * }
 */
export async function createMapModule(wasmPath, options) {
  if (!options || !options.canvas) {
    throw new Error("createMapModule: 'options.canvas' is required (element or selector string).");
  }

  let canvas = options.canvas;
  if (typeof canvas === 'string') {
    canvas = document.querySelector(canvas);
    if (!canvas) {
      throw new Error(`createMapModule: Canvas element not found for selector "${options.canvas}".`);
    }
  }

  // Check for WebGL2 support early
  const gl = canvas.getContext('webgl2');
  if (!gl) {
    throw new Error("createMapModule: WebGL2 is not supported by this browser.");
  }

  const host = new Host(canvas);

  try {
    await host.load(wasmPath);
    await host.initialize();

    if (options.initialViewport) {
      host.resize(options.initialViewport.width, options.initialViewport.height);
    }
  } catch (err) {
    // Enhance error message if it's likely a Wasm issue
    if (err instanceof WebAssembly.CompileError || err instanceof WebAssembly.LinkError) {
      throw new Error(`createMapModule: Failed to instantiate Wasm module "${wasmPath}". Verify the file exists and is a valid Terra map module. Details: ${err.message}`);
    }
    throw err;
  }

  return host;
}
