#ifndef __PROGRAM_H
#define __PROGRAM_H

void program_loaddata();
void program_init();
void program_update();

extern void program_mainloop();

extern void irq_main();

extern uint8_t program_state;

extern uint8_t xoffset;

extern uint8_t columnlo;
extern uint8_t columnhi;

extern uint8_t perspbaseheight;
extern uint8_t perspheight;
extern uint8_t perspscalelo;
extern uint8_t perspscalehi;
extern uint8_t perspxoffs;

#endif