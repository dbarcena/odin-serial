package serial

import "base:runtime"
import "core:log"
import "core:sync/chan"
import "core:time"
import "core:strings"
import "core:fmt"

SerialAsync :: struct {
	s:       Serial,
	rx_chan: chan.Chan([]u8),
	tx_chan: chan.Chan([]u8),
	data: [dynamic]u8,
	run:     bool,
}

serialasync_open :: proc(sa: ^SerialAsync, dev: string, baud: Baud_Rate, size: u8) -> bool {

	if !serial_open(&sa.s, dev, baud, size) {
		return false
	}

	rx_chan: chan.Chan([]u8)
	tx_chan: chan.Chan([]u8)
	err: runtime.Allocator_Error

	rx_chan, err = chan.create(chan.Chan([]u8), 64, context.allocator)
	if err != .None {
		serial_close(&sa.s)
		return false
	}

	tx_chan, err = chan.create(chan.Chan([]u8), 64, context.allocator)
	if err != .None {
		serial_close(&sa.s)
		chan.destroy(rx_chan)
		return false
	}

	sa.rx_chan = rx_chan
	sa.tx_chan = tx_chan
	sa.data = make([dynamic]u8, 0)
	return true
}

serialasync_close :: proc(sa: ^SerialAsync) {
	serial_close(&sa.s)
	chan.destroy(sa.rx_chan)
	chan.destroy(sa.tx_chan)

}

serialasync_send :: proc(sa: ^SerialAsync, data: []u8) -> bool {
	return chan.send(sa.tx_chan, data)
}

serialasync_async :: proc(sa: ^SerialAsync) {

	context.logger = log.create_console_logger()
	defer log.destroy_console_logger(context.logger)

	log.info("Comienza hilo")

	sa.run = true
	buf: [1024]u8

	for sa.run {
		value, ok := chan.try_recv(sa.tx_chan)

		if ok {
			serial_send(&sa.s,value)
		}

		if serial_queryRecv(&sa.s) > 0 {
			read_n := serial_recv(&sa.s, buf[:])
			if read_n > 0 {
				received_data := make([]u8, read_n)
				copy(received_data, buf[:read_n])
				chan.send(sa.rx_chan, received_data)
			}
		}

		time.sleep(10 * time.Millisecond)
	}

	log.info("Finaliza hilo")
}

serialasync_stop :: proc(sa: ^SerialAsync) {
	sa.run = false
}


serialasync_read_frame :: proc(sa: ^SerialAsync, final : string) -> string {

	for {
		value, ok := chan.try_recv(sa.rx_chan)
		if ok {
			append(&sa.data, ..value[:])
		}

		for i := 0; i <= len(sa.data) - len(final); i += 1 {
            if string(sa.data[i:i+len(final)]) == final {
                result := strings.clone_from_bytes(sa.data[:i])  // copia antes de modificar
                remove_range(&sa.data, 0, i+len(final))          // elimina lo consumido
                return result
            }
        }
	}

	return ""
}
