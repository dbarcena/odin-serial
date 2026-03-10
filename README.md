# odin-serialport

This project is based on the project `github.com/jasonKercher/serial`, which is a wrapper for serial communication on Windows and Linux. The original project did not compile with the Odin version `dev-2026-03-nightly:6d9a611`, so I created this fork to adapt it to my needs and to serve as practice for using external C libraries in Odin.



## INSTALL AND USE

Clone the repository into the `vendor` folder of your project `git clone https://github.com/dbarcena/odin-serial.git vendor/serial`


```odin
import "vendor/serial"
```

## open

Opens the serial port, taking a pointer to a Serial structure, the port name, the baud rate, and the number of data bits. Returns true if the port was opened successfully or false if an error occurred.

```odin
  if serial.open(&s, "COM3", serial.Baud_Rate.B115200 ,8)  {
    log.info("Open serial port.")
  } else {
    log.error("Failed to open serial port.")
    return
  }
```

## close

Closes the serial port.

## queryRecv

Checks whether data is available to read without blocking execution. Returns the number of bytes available, or -1 if an error occurs.

```odin
  n: int = serial.queryRecv(&s, buf[:])
  log.info("Bytes available to read: %d", n)
```

## recv

Retrieves as much available data as can fit into the provided buffer. Returns the number of bytes read or -1 if an error occurs.

```odin
  var buf: [64]u8
  n: int = serial.recv(&s, buf[:])
  log.info("Read %d bytes.", n)
```

## send

Sends the specified number of bytes from the provided buffer. Returns the number of bytes written or -1 if an error occurs.

```odin
  data: [5]u8 = [5]u8{1, 2, 3, 4, 5}
  n: int = serial.send(&s, data[:])
  log.info("Written %d bytes.", n)
```
