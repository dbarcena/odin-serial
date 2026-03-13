package serial

import "core:sync/chan"
import win32 "core:sys/windows"
import "core:time"

Baud_Rate :: enum u32 {
	B2400   = 2400,
	B4800   = 4800,
	B9600   = 9600,
	B14400  = 14400,
	B19200  = 19200,
	B38400  = 38400,
	B57600  = 57600,
	B115200 = 115200,
}


Serial :: struct {
	handle:  win32.HANDLE,
	dcb:     win32.DCB,
}

serial_open :: proc(s: ^Serial, dev: string, baud: Baud_Rate, size: u8) -> bool {

	win32.SetLastError(0)
	device_wstring := win32.utf8_to_wstring(dev)

	s.handle = win32.CreateFileW(
		device_wstring,
		win32.GENERIC_READ | win32.GENERIC_WRITE,
		0,
		nil,
		win32.OPEN_EXISTING,
		win32.FILE_ATTRIBUTE_NORMAL,
		nil,
	)
	if s.handle == win32.INVALID_HANDLE {
		return false
	}


	stat: win32.COMSTAT
	errors: win32.Com_Error
	if win32.ClearCommError(s.handle, &errors, &stat) == win32.FALSE {
		return false
	}

	// ------------------------------------------------------------------------------
	// ------------------------------------------------------------------------------
	s.dcb.DCBlength = size_of(s.dcb)

	win32.GetCommState(s.handle, &s.dcb)

	new_dcb := s.dcb
	new_dcb.BaudRate = u32(baud)
	new_dcb.ByteSize = win32.BYTE(size)
	new_dcb.StopBits = .One
	new_dcb.Parity = .None
	new_dcb.DCBlength = size_of(s.dcb) // never know...

	win32.SetCommState(s.handle, &new_dcb)

	// ------------------------------------------------------------------------------
	// Configurar timeouts
	// ------------------------------------------------------------------------------
	timeouts: win32.COMMTIMEOUTS
	timeouts.ReadIntervalTimeout = 50
	timeouts.ReadTotalTimeoutMultiplier = 10
	timeouts.ReadTotalTimeoutConstant = 100
	timeouts.WriteTotalTimeoutMultiplier = 10
	timeouts.WriteTotalTimeoutConstant = 100
	win32.SetCommTimeouts(s.handle, &timeouts)


	// ------------------------------------------------------------------------------
	return true

}

serial_close :: proc(s: ^Serial) {
	if s.handle != win32.INVALID_HANDLE {
		win32.CloseHandle(s.handle)
	}
	s.handle = win32.INVALID_HANDLE
}

serial_queryRecv :: proc(s: ^Serial) -> int {

	if s.handle == win32.INVALID_HANDLE {
		return -1
	}

	nError: win32.Com_Error
	cs: win32.COMSTAT

	if !win32.ClearCommError(s.handle, &nError, &cs) {
		return -1
	}

	if nError != {} {
		return -1
	}
	return int(cs.cbInQue)
}

serial_recv :: proc(s: ^Serial, buf: []u8) -> int {

	nBytes := serial_queryRecv(s)
	if (nBytes <= 0) {
		return nBytes
	}

	read_u32: u32 = u32(nBytes)
	if read_u32 > u32(len(buf)) {
		read_u32 = u32(len(buf))
	}

	if win32.ReadFile(s.handle, &buf[0], u32(read_u32), &read_u32, nil) == win32.FALSE {
		return -1
	}
	return int(read_u32)
}

serial_send :: proc(s: ^Serial, data: []u8) -> int {

	if s.handle == win32.INVALID_HANDLE {
		return -1
	}

	if len(data) == 0 {
		return 0
	}

	write_u32: u32
	if win32.WriteFile(s.handle, &data[0], u32(len(data)), &write_u32, nil) == win32.FALSE {
		return -1
	}

	return int(write_u32)
}
