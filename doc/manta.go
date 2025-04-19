package title

import (
	"goridium/pkg/core"
	"math"

	"goridium/pkg/assets"
	"goridium/pkg/component"
	"goridium/pkg/mat4"

	"github.com/hajimehoshi/ebiten/v2"
	"golang.org/x/image/math/f32"
)

const (
	voxelMantaRenderSize = 128
)

type Manta struct {
	component.BaseComponent
	buffer           *ebiten.Image
	preprocessBuffer *ebiten.Image
	voxelShader      *ebiten.Shader
	exhaustShader    *ebiten.Shader
	mantaAtlas       *ebiten.Image
	time             float32
	sliceSize        [2]float32
	sliceCount       int
	modelMatrix      f32.Mat4
	lightDirection   f32.Vec3
}

func (vm *Manta) Init() {
	// --- Load Shaders ---
	shaderBytes := assets.LoadBytes("shaders/voxel.kage")
	voxelShader, err := ebiten.NewShader(shaderBytes)
	if err != nil {
		core.Panicf("Manta: failed to load voxel shader: %v", err)
	}
	vm.voxelShader = voxelShader

	exhaustBytes := assets.LoadBytes("shaders/exhaust.kage")
	exhaustShader, err := ebiten.NewShader(exhaustBytes)
	if err != nil {
		core.Panicf("Manta: failed to load exhaust shader: %v", err)
	}
	vm.exhaustShader = exhaustShader

	// --- Load Voxel Atlas Texture ---
	mantaAtlas := assets.LoadImage("entities/manta_19.png")
	vm.mantaAtlas = mantaAtlas
	atlasWidth := float32(vm.mantaAtlas.Bounds().Dx())
	atlasHeight := float32(vm.mantaAtlas.Bounds().Dy())
	if atlasWidth <= 0 || atlasHeight <= 0 {
		core.Panicf("Manta: Invalid manta atlas dimensions (w: %f, h: %f)", atlasWidth, atlasHeight)
	}

	// --- Calculate Slice Info ---
	vm.sliceCount = 19
	vm.sliceSize = [2]float32{atlasWidth, atlasHeight / float32(vm.sliceCount)} // Width, Height
	if vm.sliceCount <= 0 {
		core.Panicf("Manta: Calculated slice count <= 0. AtlasH: %f, SliceH: %f", atlasHeight, vm.sliceSize[1])
	}
	core.Infof("Atlas loaded (%fx%f). SliceSize=(%f,%f), SliceCount=%d",
		atlasWidth, atlasHeight, vm.sliceSize[0], vm.sliceSize[1], vm.sliceCount)

	vm.buffer = ebiten.NewImage(voxelMantaRenderSize, voxelMantaRenderSize)
	vm.preprocessBuffer = ebiten.NewImage(int(atlasWidth), int(atlasHeight))

	// --- Init matrices & Light ---
	vm.modelMatrix = mat4.Identity4()
	vm.lightDirection = f32.Vec3{0.577, 0.577, -0.577}
	vm.time = 0.0
}

func (vm *Manta) Update(dt float64) {
	vm.time += float32(dt)

	// Define desired scale factors
	scaleMatrix := mat4.Scale4(0.7, 0.25, 0.7)

	// Slow rotation around all axes
	rotX := mat4.RotateX(vm.time * 0.6)
	rotY := mat4.RotateY(vm.time * 0.5)
	rotZ := mat4.RotateZ(vm.time * 0.4)
	// rotX = mat4.RotateX(2.2)
	// rotY = mat4.RotateY(0.1)
	// rotZ = mat4.RotateZ(0.1)
	rotationMatrix := mat4.Mul4(rotZ, mat4.Mul4(rotY, rotX))

	// Combine scale and rotation (Scale first, then rotate)
	vm.modelMatrix = mat4.Mul4(scaleMatrix, rotationMatrix)
}

func (vm *Manta) Draw(screen *ebiten.Image, op *ebiten.DrawImageOptions) {
	// Preprocess with exhaust shader
	vm.applyExhaustShader(vm.mantaAtlas, vm.preprocessBuffer)

	// Render voxel manta to offscreen buffer using DrawTrianglesShader
	{
		// Calculate inverse model matrix
		modelInverse, ok := mat4.Invert(vm.modelMatrix)
		if !ok {
			core.Warnf("WARN: Failed to invert model matrix! Using identity. Time: %f", vm.time)
			modelInverse = mat4.Identity4()
		}

		// --- Uniforms for the matrix-based Kage shader ---
		uniforms := map[string]any{
			// Camera/World Setup
			"VoxelModelMatrixInverse": mat4.Mat4ToSlice(modelInverse),

			// Light Direction
			"LightDirection": vm.lightDirection[:],

			// Atlas/Sampling Params
			"FrameSize": vm.sliceSize[:],
			"Frames":    float32(vm.sliceCount),

			// Rendering Params
			"RenderMode": int(0), // 0=Color, 1=Shadow, 2=Debug
		}

		// --- Vertices for the destination rectangle (size of vm.buffer) ---
		w := float32(voxelMantaRenderSize)
		h := float32(voxelMantaRenderSize)
		// SrcX/Y are not used by the shader's ray generation but needed by DrawTrianglesShader
		atlasW := float32(vm.mantaAtlas.Bounds().Dx())
		atlasH := float32(vm.mantaAtlas.Bounds().Dy())
		vertices := []ebiten.Vertex{
			{DstX: 0, DstY: 0, SrcX: 0, SrcY: 0, ColorR: 1, ColorG: 1, ColorB: 1, ColorA: 1},
			{DstX: w, DstY: 0, SrcX: atlasW, SrcY: 0, ColorR: 1, ColorG: 1, ColorB: 1, ColorA: 1},
			{DstX: 0, DstY: h, SrcX: 0, SrcY: atlasH, ColorR: 1, ColorG: 1, ColorB: 1, ColorA: 1},
			{DstX: w, DstY: h, SrcX: atlasW, SrcY: atlasH, ColorR: 1, ColorG: 1, ColorB: 1, ColorA: 1},
		}
		indices := []uint16{0, 1, 2, 1, 3, 2}

		// --- DrawTrianglesShader Options ---
		opts := &ebiten.DrawTrianglesShaderOptions{}
		opts.Uniforms = uniforms
		opts.Images[0] = vm.preprocessBuffer // Use preprocessed image

		// --- Draw call ---
		vm.buffer.Clear()
		vm.buffer.DrawTrianglesShader(vertices, indices, vm.voxelShader, opts)
	}

	// Draw the buffer onto the screen (same as before)
	{
		opts := &ebiten.DrawImageOptions{}
		// Center the buffer on screen (assuming screen size > buffer size)
		// opts.GeoM.Scale(0.5, 0.5)
		opts.GeoM.Translate(160-64, 120-64)
		// opts.Filter = ebiten.FilterNearest
		screen.DrawImage(vm.buffer, opts)
	}
}

func (vm *Manta) applyExhaustShader(src *ebiten.Image, dst *ebiten.Image) {
	thrust := math.Sin(float64(vm.time*4))*4 + 4
	thrust = 5
	uniforms := map[string]any{
		"ModelMatrixInverse": mat4.Mat4ToSlice(mat4.Identity4()),
		"RenderMode":         0,
		"TargetColor":        []float32{1.0, 0.0, 0.215, 1.0}, // ff0037
		"ColorVariance":      float32(0.1),
		"Time":               vm.time,
		"ExhaustLength":      float32(thrust),
		// add colors according to exhaust5.kage.go:
		//var FlameBaseColor vec4  // Base color (blue tone) - default is (0.1, 0.3, 0.7, 0.8)
		//var FlameTipColor vec4   // Tip color (white-blue tone) - default is (0.9, 0.95, 1.0, 0.95)
		"FlameBaseColor": []float32{0.8, 0.0, 0.0, 1.0},
		"FlameTipColor":  []float32{0.8, 0.6, 0.0, 1.0},
		"Color0":         []float32{0.1, 1.0, 1.0}, // Red
		"Color1":         []float32{0.0, 1.0, 1.0}, // Orange
		"Color2":         []float32{0.0, 0.0, 1.0}, // Yellow
		"Color3":         []float32{0.0, 0.0, 0.5}, // Dark Red
		"Color4":         []float32{0.0, 0.0, 0.0}, // Black
	}

	// Use atlas dimensions for source texture
	w := float32(src.Bounds().Dx())
	h := float32(src.Bounds().Dy())
	vertices := []ebiten.Vertex{
		{DstX: 0, DstY: 0, SrcX: 0, SrcY: 0, ColorR: 1, ColorG: 1, ColorB: 1, ColorA: 1},
		{DstX: w, DstY: 0, SrcX: w, SrcY: 0, ColorR: 1, ColorG: 1, ColorB: 1, ColorA: 1},
		{DstX: 0, DstY: h, SrcX: 0, SrcY: h, ColorR: 1, ColorG: 1, ColorB: 1, ColorA: 1},
		{DstX: w, DstY: h, SrcX: w, SrcY: h, ColorR: 1, ColorG: 1, ColorB: 1, ColorA: 1},
	}
	indices := []uint16{0, 1, 2, 1, 3, 2}

	opts := &ebiten.DrawTrianglesShaderOptions{}
	opts.Uniforms = uniforms
	opts.Images[0] = src

	dst.Clear()
	dst.DrawTrianglesShader(vertices, indices, vm.exhaustShader, opts)
}
