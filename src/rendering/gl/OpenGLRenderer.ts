import { mat4, vec4 } from 'gl-matrix';
import Drawable from './Drawable';
import Camera from '../../Camera';
import { gl } from '../../globals';
import ShaderProgram from './ShaderProgram';

// In this file, `gl` is accessible because it is imported above
class OpenGLRenderer {
  constructor(public canvas: HTMLCanvasElement) {
  }

  setClearColor(r: number, g: number, b: number, a: number) {
    gl.clearColor(r, g, b, a);
  }

  setSize(width: number, height: number) {
    this.canvas.width = width;
    this.canvas.height = height;
  }

  clear() {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
  }

  render(camera: Camera, prog: ShaderProgram, drawables: Array<Drawable>, inputColor: Array<number> = [1, 0, 0, 1], freq: number, noiseOption: number = 0) {
    let model = mat4.create();
    let viewProj = mat4.create();
    let color = vec4.fromValues(inputColor[0], inputColor[1], inputColor[2], inputColor[3]);

    mat4.identity(model);
    mat4.multiply(viewProj, camera.projectionMatrix, camera.viewMatrix);
    prog.setModelMatrix(model);
    prog.setViewProjMatrix(viewProj);
    prog.setGeometryColor(color);
    gl.uniform1f(gl.getUniformLocation(prog.prog, "u_Frequency"), freq);
    gl.uniform1i(gl.getUniformLocation(prog.prog, "u_Noise"), noiseOption);
    gl.uniform1f(gl.getUniformLocation(prog.prog, "u_Time"), performance.now() / 1000);
    gl.uniform3fv(gl.getUniformLocation(prog.prog, "u_Camera"), camera.controls.eye);
    for (let drawable of drawables) {
      prog.draw(drawable);
    }
  }
};

export default OpenGLRenderer;
