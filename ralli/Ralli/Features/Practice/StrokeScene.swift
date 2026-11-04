import SwiftUI
import SceneKit
import UIKit
import simd

/// A lit 3D court with a player who performs a `StrokeMotion`.
/// SwiftUI drives `progress`; this view only places nodes, so it stays cheap per frame.
struct StrokeSceneView: UIViewRepresentable {
    let motion: StrokeMotion
    let progress: Double
    let camera: MotionCamera
    var effects = true
    var animateCamera = true

    func makeCoordinator() -> StrokeSceneRig { StrokeSceneRig() }
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.cameraNode
        view.backgroundColor = UIColor(RalliTheme.ink)
        view.antialiasingMode = .multisampling4X
        view.isUserInteractionEnabled = false   // never steal the page's scroll
        view.preferredFramesPerSecond = 60
        view.isAccessibilityElement = false
        context.coordinator.apply(motion: motion, progress: progress, camera: camera, effects: effects, animateCamera: false)
        return view
    }
    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.apply(motion: motion, progress: progress, camera: camera, effects: effects, animateCamera: animateCamera)
    }
}

final class StrokeSceneRig {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    private let player = SCNNode()
    private var limbs: [String: SCNNode] = [:]
    private let torso = SCNNode(), head = SCNNode(), hair = SCNNode(), visor = SCNNode()
    private let racket = SCNNode(), ball = SCNNode(), impactRing = SCNNode(), swoosh = SCNNode()
    private var lastCamera: MotionCamera?
    private var lastMotionID: String?

    // MARK: Palette
    private static let skin = UIColor(red: 0.80, green: 0.60, blue: 0.47, alpha: 1)
    private static let shirt = UIColor(RalliTheme.clay)
    private static let shorts = UIColor(red: 0.11, green: 0.17, blue: 0.14, alpha: 1)
    private static let white = UIColor(RalliTheme.paper)
    private static let lime = UIColor(RalliTheme.lime)
    private static let court = UIColor(red: 0.20, green: 0.36, blue: 0.29, alpha: 1)
    private static let surround = UIColor(red: 0.13, green: 0.23, blue: 0.18, alpha: 1)
    private static let horizon = UIColor(red: 0.27, green: 0.40, blue: 0.33, alpha: 1)
    private static func skyImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 512)).image { context in
            let colors = [UIColor(red: 0.10, green: 0.17, blue: 0.13, alpha: 1).cgColor, UIColor(RalliTheme.ink).cgColor, horizon.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 0.45, 1])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 512), options: [])
        }
    }

    init() {
        // Evening sky: deep ink above, a soft green glow at the horizon that the far court fades into.
        scene.background.contents = Self.skyImage()
        scene.fogColor = Self.horizon
        scene.fogStartDistance = 8
        scene.fogEndDistance = 30
        buildCourt()
        buildLights()
        buildPlayer()
        buildCamera()
    }

    // MARK: Scene construction
    private static func material(_ color: UIColor, shiny: Bool = false, constant: Bool = false) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.lightingModel = constant ? .constant : .blinn
        m.specular.contents = UIColor(white: shiny ? 0.6 : 0.12, alpha: 1)
        m.shininess = shiny ? 0.6 : 0.15
        return m
    }
    private func box(width: CGFloat, length: CGFloat, at position: SCNVector3, color: UIColor) -> SCNNode {
        let geometry = SCNBox(width: width, height: 0.004, length: length, chamferRadius: 0)
        geometry.materials = [Self.material(color)]
        let node = SCNNode(geometry: geometry)
        node.position = position
        return node
    }
    private func buildCourt() {
        let ground = SCNPlane(width: 120, height: 120)
        ground.materials = [Self.material(Self.surround)]
        let groundNode = SCNNode(geometry: ground)
        groundNode.eulerAngles.x = -.pi / 2
        groundNode.position = SCNVector3(11.885, 0, 0)
        scene.rootNode.addChildNode(groundNode)

        let surface = SCNPlane(width: 23.77 + 6, height: 10.97 + 5)
        surface.materials = [Self.material(Self.court)]
        let surfaceNode = SCNNode(geometry: surface)
        surfaceNode.eulerAngles.x = -.pi / 2
        surfaceNode.position = SCNVector3(11.885, 0.002, 0)
        scene.rootNode.addChildNode(surfaceNode)

        let line = Self.white, w: CGFloat = 0.05
        let lines = SCNNode()
        for x in [0.0, 23.77] { lines.addChildNode(box(width: w, length: 10.97, at: SCNVector3(x, 0.005, 0), color: line)) }
        for z in [-5.485, 5.485, -4.115, 4.115] { lines.addChildNode(box(width: 23.77, length: w, at: SCNVector3(11.885, 0.005, z), color: line)) }
        for x in [5.485, 18.285] { lines.addChildNode(box(width: w, length: 8.23, at: SCNVector3(x, 0.005, 0), color: line)) }
        lines.addChildNode(box(width: 12.8, length: w, at: SCNVector3(11.885, 0.005, 0), color: line))
        for x in [0.05, 23.72] { lines.addChildNode(box(width: 0.1, length: w, at: SCNVector3(x, 0.005, 0), color: line)) }
        scene.rootNode.addChildNode(lines)

        // Net: posts, a see-through mesh and the white tape.
        let net = SCNNode()
        for z in [-6.4, 6.4] {
            let post = SCNNode(geometry: SCNCylinder(radius: 0.04, height: 1.07))
            post.geometry?.materials = [Self.material(UIColor(white: 0.85, alpha: 1), shiny: true)]
            post.position = SCNVector3(11.885, 0.535, z)
            net.addChildNode(post)
        }
        let mesh = SCNPlane(width: 12.8, height: 0.88)
        let meshMaterial = SCNMaterial()
        meshMaterial.diffuse.contents = Self.gridImage(size: CGSize(width: 1024, height: 72), spacing: 9, color: UIColor(white: 0.05, alpha: 0.8))
        meshMaterial.diffuse.wrapS = .repeat
        meshMaterial.isDoubleSided = true
        meshMaterial.lightingModel = .constant
        mesh.materials = [meshMaterial]
        let meshNode = SCNNode(geometry: mesh)
        meshNode.eulerAngles.y = .pi / 2
        meshNode.position = SCNVector3(11.885, 0.47, 0)
        meshNode.castsShadow = false
        net.addChildNode(meshNode)
        let tape = SCNNode(geometry: SCNBox(width: 0.03, height: 0.06, length: 12.8, chamferRadius: 0.01))
        tape.geometry?.materials = [Self.material(Self.white)]
        tape.position = SCNVector3(11.885, 0.9, 0)
        net.addChildNode(tape)
        scene.rootNode.addChildNode(net)
    }
    private func buildLights() {
        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .directional
        sun.light?.intensity = 1100
        sun.light?.color = UIColor(red: 1, green: 0.96, blue: 0.88, alpha: 1)
        sun.light?.castsShadow = true
        sun.light?.shadowMode = .forward
        sun.light?.shadowRadius = 4
        sun.light?.shadowSampleCount = 12
        sun.light?.shadowColor = UIColor(white: 0, alpha: 0.5)
        sun.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        sun.light?.automaticallyAdjustsShadowProjection = true
        sun.light?.maximumShadowDistance = 14
        sun.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 5, 0)
        scene.rootNode.addChildNode(sun)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .ambient
        fill.light?.intensity = 420
        fill.light?.color = UIColor(red: 0.78, green: 0.86, blue: 0.82, alpha: 1)
        scene.rootNode.addChildNode(fill)

        // Soft back light so the silhouette separates from the dark court.
        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.intensity = 380
        rim.light?.color = UIColor(red: 0.85, green: 0.93, blue: 0.7, alpha: 1)
        rim.eulerAngles = SCNVector3(-Float.pi / 6, Float.pi, 0)
        scene.rootNode.addChildNode(rim)
    }
    private func limb(_ name: String, _ color: UIColor, radius: CGFloat) {
        let node = SCNNode(geometry: SCNCapsule(capRadius: radius, height: radius * 2 + 0.1))
        node.geometry?.materials = [Self.material(color)]
        limbs[name] = node
        player.addChildNode(node)
    }
    private func buildPlayer() {
        scene.rootNode.addChildNode(player)
        // Order matters only for readability: skin first, clothes over it.
        for (name, radius) in [("rUpper", 0.047), ("lUpper", 0.047), ("rFore", 0.04), ("lFore", 0.04), ("neck", 0.05),
                               ("rThigh", 0.068), ("lThigh", 0.068), ("rShin", 0.052), ("lShin", 0.052)] {
            limb(name, Self.skin, radius: radius)
        }
        for (name, radius) in [("rSleeve", 0.064), ("lSleeve", 0.064), ("shoulders", 0.08)] { limb(name, Self.shirt, radius: radius) }
        for (name, radius) in [("hips", 0.125), ("rShorts", 0.085), ("lShorts", 0.085)] { limb(name, Self.shorts, radius: radius) }
        for (name, radius) in [("rSock", 0.057), ("lSock", 0.057), ("rShoe", 0.058), ("lShoe", 0.058)] { limb(name, Self.white, radius: radius) }
        for (name, radius) in [("rHand", 0.048), ("lHand", 0.048)] {
            let node = SCNNode(geometry: SCNSphere(radius: radius))
            node.geometry?.materials = [Self.material(Self.skin)]
            limbs[name] = node; player.addChildNode(node)
        }
        torso.geometry = SCNCapsule(capRadius: 0.13, height: 0.6)
        torso.geometry?.materials = [Self.material(Self.shirt)]
        player.addChildNode(torso)
        head.geometry = SCNSphere(radius: 0.112)
        head.geometry?.materials = [Self.material(Self.skin)]
        player.addChildNode(head)
        // White cap with a visor: shows at a glance which way the player is looking.
        let capMaterial = Self.material(Self.white)
        let crown = SCNSphere(radius: 0.12)
        crown.materials = [capMaterial]
        hair.geometry = crown
        hair.scale = SCNVector3(1, 0.72, 1)
        player.addChildNode(hair)
        let brim = SCNCylinder(radius: 0.085, height: 0.012)
        brim.materials = [Self.material(UIColor(white: 0.9, alpha: 1))]
        visor.geometry = brim
        visor.scale = SCNVector3(1, 1, 0.75)
        player.addChildNode(visor)

        buildRacket()
        player.addChildNode(racket)

        ball.geometry = SCNSphere(radius: 0.042)
        let ballMaterial = Self.material(Self.lime)
        ballMaterial.emission.contents = Self.lime.withAlphaComponent(0.45)
        ball.geometry?.materials = [ballMaterial]
        player.addChildNode(ball)

        let ring = SCNTorus(ringRadius: 0.12, pipeRadius: 0.008)
        let ringMaterial = Self.material(Self.lime, constant: true)
        ringMaterial.writesToDepthBuffer = false
        ring.materials = [ringMaterial]
        impactRing.geometry = ring
        impactRing.castsShadow = false
        player.addChildNode(impactRing)

        swoosh.castsShadow = false
        player.addChildNode(swoosh)
    }
    private func buildRacket() {
        let lime = Self.material(Self.lime, shiny: true)
        let grip = SCNNode(geometry: SCNCapsule(capRadius: 0.017, height: 0.22))
        grip.geometry?.materials = [Self.material(UIColor(white: 0.12, alpha: 1))]
        grip.position = SCNVector3(0, 0.07, 0)
        racket.addChildNode(grip)
        for side in [-1.0, 1.0] {
            let throat = SCNNode(geometry: SCNCapsule(capRadius: 0.009, height: 0.17))
            throat.geometry?.materials = [lime]
            throat.position = SCNVector3(Float(side * 0.03), 0.27, 0)
            throat.eulerAngles.z = Float(-side * 0.32)
            racket.addChildNode(throat)
        }
        let headNode = SCNNode()
        headNode.position = SCNVector3(0, Float(MotionPose.racketHeadOffset), 0)
        headNode.scale = SCNVector3(1, 1.3, 1)
        let frame = SCNNode(geometry: SCNTorus(ringRadius: 0.118, pipeRadius: 0.011))
        frame.geometry?.materials = [lime]
        frame.eulerAngles.x = .pi / 2
        headNode.addChildNode(frame)
        let strings = SCNPlane(width: 0.232, height: 0.232)
        strings.cornerRadius = 0.116
        let stringMaterial = SCNMaterial()
        stringMaterial.diffuse.contents = Self.gridImage(size: CGSize(width: 128, height: 128), spacing: 9, color: UIColor(white: 0.97, alpha: 0.85))
        stringMaterial.isDoubleSided = true
        stringMaterial.lightingModel = .lambert
        strings.materials = [stringMaterial]
        let stringNode = SCNNode(geometry: strings)
        stringNode.castsShadow = false
        headNode.addChildNode(stringNode)
        racket.addChildNode(headNode)
    }
    private func buildCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 38
        camera.zNear = 0.05
        camera.zFar = 80
        camera.wantsHDR = true
        camera.bloomIntensity = 0.5
        camera.bloomThreshold = 0.85
        camera.bloomBlurRadius = 6
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = 0.15
        camera.wantsDepthOfField = true
        camera.fStop = 5.6
        camera.focalBlurSampleCount = 8
        cameraNode.camera = camera
        scene.rootNode.addChildNode(cameraNode)
    }
    private static func gridImage(size: CGSize, spacing: CGFloat, color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            color.setStroke()
            let path = UIBezierPath()
            path.lineWidth = 1.4
            var x: CGFloat = 0
            while x <= size.width { path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height)); x += spacing }
            var y: CGFloat = 0
            while y <= size.height { path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y)); y += spacing }
            path.stroke()
            _ = context
        }
    }

    // MARK: Per-frame update
    func apply(motion: StrokeMotion, progress: Double, camera: MotionCamera, effects: Bool, animateCamera: Bool) {
        SCNTransaction.begin()
        SCNTransaction.disableActions = true
        player.simdPosition = SIMD3(Float(motion.courtX), 0, 0)
        let pose = motion.pose(at: progress)
        place(pose)
        updateEffects(motion: motion, progress: progress, pose: pose, enabled: effects)
        SCNTransaction.commit()
        if camera != lastCamera || motion.id != lastMotionID {
            moveCamera(to: camera, motion: motion, animated: animateCamera && lastCamera != nil)
            lastCamera = camera; lastMotionID = motion.id
        }
    }
    private func v(_ p: V3) -> SIMD3<Float> { SIMD3(Float(p.x), Float(p.y), Float(p.z)) }
    private func stretch(_ name: String, _ a: V3, _ b: V3) {
        guard let node = limbs[name], let capsule = node.geometry as? SCNCapsule else { return }
        stretch(node, capsule, v(a), v(b))
    }
    private func stretch(_ node: SCNNode, _ capsule: SCNCapsule, _ a: SIMD3<Float>, _ b: SIMD3<Float>) {
        let delta = b - a
        let length = simd_length(delta)
        capsule.height = CGFloat(length) + capsule.capRadius * 2
        node.simdPosition = (a + b) / 2
        node.simdOrientation = length > 1e-5 ? simd_quatf(from: SIMD3(0, 1, 0), to: delta / length) : simd_quatf(angle: 0, axis: SIMD3(0, 1, 0))
    }
    private func mix(_ a: V3, _ b: V3, _ t: Double) -> V3 { a + (b - a) * t }
    private func place(_ p: MotionPose) {
        stretch("rUpper", p.rightShoulder, p.rightElbow); stretch("lUpper", p.leftShoulder, p.leftElbow)
        stretch("rSleeve", p.rightShoulder, mix(p.rightShoulder, p.rightElbow, 0.45)); stretch("lSleeve", p.leftShoulder, mix(p.leftShoulder, p.leftElbow, 0.45))
        stretch("rFore", p.rightElbow, p.rightHand); stretch("lFore", p.leftElbow, p.leftHand)
        stretch("shoulders", p.rightShoulder, p.leftShoulder)
        stretch("neck", p.chest, p.neck + V3(0, 0.05, 0))
        stretch("hips", p.rightHip, p.leftHip)
        stretch("rThigh", p.rightHip, p.rightKnee); stretch("lThigh", p.leftHip, p.leftKnee)
        stretch("rShorts", p.rightHip, mix(p.rightHip, p.rightKnee, 0.55)); stretch("lShorts", p.leftHip, mix(p.leftHip, p.leftKnee, 0.55))
        stretch("rShin", p.rightKnee, p.rightAnkle); stretch("lShin", p.leftKnee, p.leftAnkle)
        stretch("rSock", p.rightAnkle, mix(p.rightAnkle, p.rightKnee, 0.22)); stretch("lSock", p.leftAnkle, mix(p.leftAnkle, p.leftKnee, 0.22))
        let rHeel = V3(p.rightAnkle.x, max(0.06, p.rightAnkle.y - 0.03), p.rightAnkle.z), lHeel = V3(p.leftAnkle.x, max(0.06, p.leftAnkle.y - 0.03), p.leftAnkle.z)
        stretch("rShoe", rHeel, p.rightToe + V3(0, 0.02, 0)); stretch("lShoe", lHeel, p.leftToe + V3(0, 0.02, 0))
        limbs["rHand"]?.simdPosition = v(p.rightHand); limbs["lHand"]?.simdPosition = v(p.leftHand)

        // Torso: wider across the shoulders than front to back.
        let up = simd_normalize(v(p.chest) - v(p.pelvis))
        var side = v(MotionPose.rightSide((p.chestYaw + p.hipYaw) / 2))
        side = simd_normalize(side - up * simd_dot(side, up))
        let front = simd_cross(up, side)
        if let capsule = torso.geometry as? SCNCapsule {
            let length = simd_length(v(p.chest) - v(p.pelvis))
            capsule.height = CGFloat(length) + 0.26
        }
        let center = (v(p.chest) + v(p.pelvis)) / 2
        torso.simdTransform = simd_float4x4(columns: (SIMD4(front * 0.78, 0), SIMD4(up, 0), SIMD4(side * 1.32, 0), SIMD4(center, 1)))
        head.simdPosition = v(p.head)
        let look = MotionPose.facing(p.chestYaw)
        hair.simdPosition = v(p.head + V3(0, 0.045, 0) - look * 0.01)
        visor.simdPosition = v(p.head + V3(0, 0.035, 0) + look * 0.105)
        visor.simdOrientation = simd_quatf(angle: Float(atan2(-look.z, look.x)), axis: SIMD3(0, 1, 0)) * simd_quatf(angle: -0.12, axis: SIMD3(0, 0, 1))

        // Racket basis: y along the shaft, z through the strings.
        let shaft = v(p.shaft), normal = v(p.stringNormal), across = simd_cross(shaft, normal)
        racket.simdTransform = simd_float4x4(columns: (SIMD4(across, 0), SIMD4(shaft, 0), SIMD4(normal, 0), SIMD4(v(p.rightHand), 1)))

        if let b = p.ball { ball.isHidden = false; ball.simdPosition = v(b) } else { ball.isHidden = true }
    }
    private func updateEffects(motion: StrokeMotion, progress: Double, pose: MotionPose, enabled: Bool) {
        // Impact ring: expands from the strings and fades.
        if enabled, let t = motion.impact(at: progress), let b = pose.ball {
            impactRing.isHidden = false
            impactRing.simdPosition = v(b)
            let normal = v(pose.stringNormal)
            impactRing.simdOrientation = simd_quatf(from: SIMD3(0, 1, 0), to: normal)
            let scale = Float(0.8 + t * 1.4)
            impactRing.simdScale = SIMD3(scale, scale, scale)
            impactRing.opacity = CGFloat(1 - t)
        } else { impactRing.isHidden = true }

        // Swoosh: a fading ribbon behind the racket head while it moves fast.
        guard enabled else { swoosh.geometry = nil; return }
        let samples = 10
        var vertices: [SCNVector3] = [], colors: [SIMD4<Float>] = []
        var travel: Float = 0
        var previous: SIMD3<Float>?
        for k in 0..<samples {
            let back = Double(samples - 1 - k) * 0.0045
            let past = motion.pose(at: progress - back)
            let inner = v(past.racketHeadCenter - past.shaft * 0.1), outer = v(past.racketTip)
            if let previous { travel += simd_length(outer - previous) }
            previous = outer
            vertices.append(SCNVector3(inner)); vertices.append(SCNVector3(outer))
            let alpha = Float(k) / Float(samples - 1)
            let fade = alpha * alpha
            colors.append(SIMD4(0.85, 0.91, 0.59, fade * 0.04)); colors.append(SIMD4(0.85, 0.91, 0.59, fade * 0.38))
        }
        // Only draw when the racket actually travels; a resting racket gets no trail.
        guard travel > 0.3 else { swoosh.geometry = nil; return }
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let colorData = colors.withUnsafeBufferPointer { Data(buffer: $0) }
        let colorSource = SCNGeometrySource(data: colorData, semantic: .color, vectorCount: colors.count, usesFloatComponents: true,
                                            componentsPerVector: 4, bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0, dataStride: MemoryLayout<SIMD4<Float>>.stride)
        var indices: [Int32] = []
        for k in 0..<(samples - 1) {
            let a = Int32(k * 2)
            indices += [a, a + 1, a + 2, a + 1, a + 3, a + 2]
        }
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: [vertexSource, colorSource], elements: [element])
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor.white
        material.isDoubleSided = true
        material.blendMode = .alpha
        material.writesToDepthBuffer = false
        geometry.materials = [material]
        swoosh.geometry = geometry
    }
    private func moveCamera(to camera: MotionCamera, motion: StrokeMotion, animated: Bool) {
        let root = SIMD3(Float(motion.courtX), 0, 0)
        let lift: Float = (motion.id == "serve" || motion.id == "overhead") ? 0.4 : 0
        let eye: SIMD3<Float>, target: SIMD3<Float>
        switch camera {
        case .side:
            let side: Float = motion.sideCameraOnLeft ? -1 : 1
            eye = SIMD3(0.45, 1.25 + lift * 0.6, side * (4.0 + lift * 1.1)); target = SIMD3(0.1, 1.0 + lift, side * 0.1)
        case .behind: eye = SIMD3(-3.3, 1.85 + lift * 0.4, 1.1); target = SIMD3(0.6, 1.05 + lift, 0.1)
        case .front: eye = SIMD3(3.2, 1.5 + lift * 0.4, 1.7); target = SIMD3(0, 1.0 + lift, 0.15)
        }
        let world = root + eye, look = root + target
        SCNTransaction.begin()
        SCNTransaction.animationDuration = animated ? 0.7 : 0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        cameraNode.simdPosition = world
        cameraNode.simdLook(at: look, up: SIMD3(0, 1, 0), localFront: SIMD3(0, 0, -1))
        cameraNode.camera?.focusDistance = CGFloat(simd_length(look - world))
        SCNTransaction.commit()
    }
}
