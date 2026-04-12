@group(0) @binding(0) var<uniform> uniforms: Uniforms;
@group(0) @binding(1) var<storage> shapes: array<Shape>;
@group(0) @binding(2) var<storage> vertices: array<Vertex>;
@group(0) @binding(3) var<storage> segments: array<Segment>;

struct Uniforms {
    resolution: vec2f,
    tile_size: u32,
}

const LINE = 0u;
const POINT = 1u;
const RECTANGLE = 2u;
const TILE = 3u;

struct Shape {
    color: vec4f,
    width: f32,
    kind: u32,
    tile: Tile,
}

struct Vertex {
    position: vec2f,
    shape: u32,
}

struct Tile {
    segment_start: u32,
    segment_end: u32,
    winding_number: i32,
}

struct Segment {
    // a: unorm8x2,
    // b: unorm8x2,
    ab: u32,
}

struct VertexOutput {
    @builtin(position) position: vec4f,
    @location(0) @interpolate(perspective, sample) p: vec2f,
    @location(1) @interpolate(flat) index: u32,
}

fn flip_y(v: vec2f) -> vec2f {
    return vec2(v.x, -v.y);
}

@vertex
fn vs_graph(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    let i = vertex_index / 6u;
    let j = vertex_index % 6u;

    let vertex = vertices[i];

    if vertex.shape == ~0u {
        return VertexOutput();
    }

    let shape = shapes[vertex.shape];
    var p: vec2f;

    if shape.kind == LINE || shape.kind == POINT {
        let p0 = vertex.position;
        var p1: vec2f;

        if shape.kind == LINE {
            let next = vertices[i + 1];
            if next.shape != vertex.shape {
                return VertexOutput();
            }
            p1 = next.position;
        } else /* if shape.kind == POINT */ {
            p1 = p0;
        }

        var t = select(normalize(p1 - p0), vec2(1.0, 0.0), all(p0 == p1));
        t *= 0.5 * shape.width;
        let n = vec2(-t.y, t.x);
        p = select(p1 + t, p0 - t, 0 < j && j < 4) + select(n, -n, 1 < j && j < 5);
    } else {
        let h = f32(uniforms.tile_size);
        let w = select(shape.width, h, shape.kind == TILE);
        let offset = vec2(select(0.0, w, 0 < j && j < 4), select(0.0, h, 1 < j && j < 5));
        p = vertex.position + offset;
    }
    
    let z = bitcast<f32>(vertex.shape + 0x00800000);
    let p_clip = vec4(flip_y(2.0 * p - uniforms.resolution) / uniforms.resolution, z, 1.0);
    return VertexOutput(p_clip, p, i);
}

fn sd_segment(p: vec2f, a: vec2f, b: vec2f) -> f32 {
    let ap = p - a;
    let ab = b - a;
    return distance(ap, saturate(dot(ap, ab) / dot(ab, ab)) * ab);
}

@fragment
fn fs_graph(in: VertexOutput) -> @location(0) vec4f {
    let vertex = vertices[in.index];
    let shape = shapes[vertex.shape];

    if shape.kind == LINE || shape.kind == POINT {
        let p0 = vertex.position;
        var p1: vec2f;

        if shape.kind == LINE {
            p1 = vertices[in.index + 1].position;
        } else /* if shape.kind == POINT */ {
            p1 = p0;
        }

        let d = sd_segment(in.p, p0, p1);

        if d > shape.width * 0.5 {
            discard;
        }
    } else if shape.kind == RECTANGLE {
        // no-op
    } else /* if shape.kind == TILE */ {
        let p = (in.p - vertex.position) / f32(uniforms.tile_size);
        var winding_number = shape.tile.winding_number;

        for (var i = shape.tile.segment_start; i < shape.tile.segment_end; i++) {
            let segment = segments[i];
            let ab = unpack4x8unorm(segment.ab);
            let a = ab.xy;
            let b = ab.zw;
            
            winding_number -= i32(a.x == 0.0 && a.y > 0.0 && a.y <= p.y);
            winding_number += i32(b.x == 0.0 && b.y > 0.0 && b.y <= p.y);

            let is_within_y_bounds = min(a.y, b.y) <= p.y && p.y < max(a.y, b.y);
            let is_right_of_segment = (b.x - a.x) * abs(p.y - a.y) < (p.x - a.x) * abs(b.y - a.y);

            if is_within_y_bounds && is_right_of_segment {
                winding_number += select(-1, 1, a.y < b.y);
            }
        }

        if winding_number == 0 {
            discard;
        }
    }

    return shape.color;
}
