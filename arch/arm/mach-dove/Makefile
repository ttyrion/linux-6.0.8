# SPDX-License-Identifier: GPL-2.0
ccflags-$(CONFIG_ARCH_MULTIPLATFORM) := -I$(srctree)/arch/arm/plat-orion/include

obj-y				+= common.o
obj-$(CONFIG_DOVE_LEGACY)	+= irq.o mpp.o
obj-$(CONFIG_PCI)		+= pcie.o
obj-$(CONFIG_MACH_DOVE_DB)	+= dove-db-setup.o
obj-$(CONFIG_MACH_CM_A510)	+= cm-a510.o
