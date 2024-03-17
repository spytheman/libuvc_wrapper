module main

import uvc
import gg
import log

fn C.uvc_any2rgb(inp &C.uvc_frame_t, out &C.uvc_frame_t) uvc.ErrorT

struct App {
mut:
	gg           &gg.Context = unsafe { nil }
	istream_idx  int
	handles      uvc.StreamingHandles
	output_frame &C.uvc_frame_t = unsafe { nil }
}

fn (mut app App) init() {
	app.istream_idx = app.gg.new_streaming_image(640, 480, 4, pixel_format: .rgba8)
	app.output_frame = C.uvc_allocate_frame(640 * 480 * 4)
	app.output_frame.width = 640
	app.output_frame.height = 480
	app.output_frame.frame_format = .rgb
	app.output_frame.library_owns_data = 0
	log.info('app.istream_idx: ${app.istream_idx}')
	log.info('app.handles: ${app.handles}')
	log.info('app.output_frame: ${app.output_frame}')
}

fn (mut app App) frame() {
	app.gg.begin()
	mut istream_image := app.gg.get_cached_image_by_idx(app.istream_idx)
	istream_image.update_pixel_data(unsafe { &u8(app.output_frame.data) })
	size := gg.window_size()
	app.gg.draw_image(0, 0, size.width, size.height, istream_image)
	app.gg.end()
}

fn cb(frame &C.uvc_frame_t, mut app App) {
	gc_disable()
	C.uvc_any2rgb(frame, app.output_frame)
	gc_enable()
}

fn main() {	
	mut app := &App{}
	app.gg = gg.new_context(
		window_title: 'Webcam Viewer'
		bg_color: gg.Color{100, 100, 100, 255}
		width: 640
		height: 480
		init_fn: app.init
		frame_fn: app.frame
		user_data: app
	)
	app.handles = uvc.start_streaming(cb, app)
	defer {
		app.handles.finish_streaming()
	}
	app.gg.run()
}
