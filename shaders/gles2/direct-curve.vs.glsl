// pathfinder/shaders/gles2/direct-curve.vs.glsl
//
// Copyright (c) 2017 The Pathfinder Project Developers.
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.

//! Implements the quadratic Loop-Blinn formulation to render curved parts of
//! the mesh.
//!
//! This shader performs no antialiasing; if you want antialiased output from
//! this shader, use MSAA with sample-level shading (GL 4.x) or else perform
//! SSAA by rendering to a higher-resolution framebuffer and downsampling (GL
//! 3.x and below).
//!
//! If you know your mesh has no curves (i.e. it consists solely of polygons),
//! then you don't need to run this shader.

precision highp float;

/// A 3D transform to be applied to all points.
uniform mat4 uTransform;
/// Vertical snapping positions.
uniform vec4 uHints;
/// The size of the path colors texture in texels.
uniform ivec2 uPathColorsDimensions;
/// The fill color for each path.
uniform sampler2D uPathColors;
/// The size of the path transform buffer texture in texels.
uniform ivec2 uPathTransformSTDimensions;
/// The path transform buffer texture, one path dilation per texel.
uniform sampler2D uPathTransformST;
/// The size of the extra path transform factors buffer texture in texels.
uniform ivec2 uPathTransformExtDimensions;
/// The extra path transform factors buffer texture, packed two path transforms per texel.
uniform sampler2D uPathTransformExt;
/// The amount of faux-bold to apply, in local path units.
uniform vec2 uEmboldenAmount;

/// The 2D position of this point.
attribute vec2 aPosition;
/// The abstract Loop-Blinn texture coordinate for this point.
attribute vec2 aTexCoord;
/// The path ID, starting from 1.
attribute float aPathID;
/// Specifies whether this is a concave or convex curve.
attribute float aSign;
/// The angle of the 2D normal for this point.
attribute float aNormalAngle;

/// The fill color of this path.
varying vec4 vColor;
/// The outgoing abstract Loop-Blinn texture coordinate.
varying vec2 vTexCoord;
/// Specifies whether this is a concave or convex curve.
varying float vSign;

void main() {
    int pathID = int(aPathID);

    vec2 pathTransformExt;
    vec4 pathTransformST = fetchPathAffineTransform(pathTransformExt,
                                                    uPathTransformST,
                                                    uPathTransformSTDimensions,
                                                    uPathTransformExt,
                                                    uPathTransformExtDimensions,
                                                    pathID);

    vec2 position = dilatePosition(aPosition, aNormalAngle, uEmboldenAmount);
    position = hintPosition(position, uHints);
    position = transformVertexPositionAffine(position, pathTransformST, pathTransformExt);
    position = transformVertexPosition(position, uTransform);

    float depth = convertPathIndexToViewportDepthValue(pathID);
    gl_Position = vec4(position, depth, 1.0);

    vColor = fetchFloat4Data(uPathColors, pathID, uPathColorsDimensions);
    vTexCoord = vec2(aTexCoord) / 2.0;
    vSign = aSign;
}
