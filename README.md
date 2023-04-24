# RISC-V slice prototype

This tutorial will guide you through building and executing our RISC-V slice
prototype using a Ubuntu Docker image. Before proceeding, please ensure that
Docker is installed on your system.

## Prerequisites

* Docker

## Quick start

Jump to [:book:quick-start](quick-start.md) if you do not want to compile from source code.

## Build from source
Follow [build tutorial](build.md) to build from source code.

## Limitations
There are some limitations of using QEMU, such as: 
* Timestamp from log is not useful since it is under QEMU.
* Slice cache will always show zero value for cache controller registers since it is unimplemented.
* UART-0 is assigned to slice-0, UART-1 is reserved for normal harts to use before they are locked into a slice, UART-2 is used by hart1 and hart2, UART2 is used by hart 3 and hart4.

