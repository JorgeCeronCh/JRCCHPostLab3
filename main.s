/*	
    Archivo:		main.S
    Dispositivo:	PIC16F887
    Autor:		Jorge Cerón 20288
    Compilador:		pic-as (v2.30), MPLABX V6.00

    Programa:		Contador hexadecimal de 4 bits
    Hardware:		Contador hexadecimal de 4 bits en 7 segmentos

    Creado:			12/02/22
    Última modificación:	12/02/22	
*/
PROCESSOR 16F887
#include <xc.inc>

; configuracion 1
  CONFIG  FOSC = INTRC_NOCLKOUT // Oscillador Interno sin salidas
  CONFIG  WDTE = OFF            // WDT (Watchdog Timer Enable bit) disabled (reinicio repetitivo del pic)
  CONFIG  PWRTE = ON            // PWRT enabled (Power-up Timer Enable bit) (espera de 72 ms al iniciar)
  CONFIG  MCLRE = OFF           // El pin de MCL se utiliza como I/O
  CONFIG  CP = OFF              // Sin proteccion de codigo
  CONFIG  CPD = OFF             // Sin proteccion de datos
  
  CONFIG  BOREN = OFF           // Sin reinicio cunado el voltaje de alimentación baja de 4V
  CONFIG  IESO = OFF            // Reinicio sin cambio de reloj de interno a externo
  CONFIG  FCMEN = OFF           // Cambio de reloj externo a interno en caso de fallo
  CONFIG  LVP = ON              // programación en bajo voltaje permitida

; configuracion  2
  CONFIG  WRT = OFF             // Protección de autoescritura por el programa desactivada
  CONFIG  BOR4V = BOR40V        // Reinicio abajo de 4V, (BOR21V = 2.1V)
 
PSECT udata_bank0
    CONT1:	    DS 1
    CONT2:	    DS 1
     
PSECT resVect, class=CODE, abs, delta=2
;----------------vector reset----------------
ORG 00h
resVect:
    PAGESEL	main    //Cambio de página
    GOTO	main
PSECT code, abs, delta=2
;----------------configuracion----------------
ORG 100h
main:
    CALL    CONFIGIO	// Se llama la rutina configuración de entradas y salidas
    CALL    CONFIGRELOJ // Se llama la rutina configuración del reloj
    CALL    CONFIGTIMER0// Se llama la rutina configuración del TMR0
    BANKSEL PORTA
    
loop:
    BTFSC   PORTA, 0	// Analiza RA0 si esta presionado (si no está presionado salta una linea) 
    CALL    SUMACONT1   // Si está presionado pasa a sumar a cont1
    BTFSC   PORTA, 1	// Analiza RA1 si esta presionado (si no está presionado salta una linea)
    CALL    RESTACONT1  // Sí está presionado pasa a restar a cont1
    CALL    CONTTIMER0	// Se llama la rutina contador del TMR0
    CALL    COMPARACION	// Se llama la rutina comparacion de contadores
    GOTO    loop	// Regresa a revisar

CONFIGIO:
    BANKSEL ANSEL	// Direccionar al banco 11
    CLRF    ANSEL	// I/O digitales
    CLRF    ANSELH	// I/O digitales
    BANKSEL TRISA	// Direccionar al banco 01
    BSF	    TRISA, 0	// RA0 como entrada
    BSF	    TRISA, 1	// RA1 como entrada
    BCF	    TRISB, 0	// RB0 como salida
    BCF	    TRISB, 1	// RB1 como salida
    BCF	    TRISB, 2	// RB2 como salida
    BCF	    TRISB, 3	// RB3 como salida
    CLRF    TRISC	// PORTC como salida
    BCF	    TRISD, 0	// RD0 como salida
    BCF	    TRISD, 1	// RD0 como salida
    BCF	    TRISD, 2	// RD0 como salida
    BCF	    TRISD, 3	// RD0 como salida
    BCF	    TRISE, 0	// RE0 como salida
    BANKSEL PORTA	// Direccionar al banco 00
    CLRF    PORTA	// Se limpia PORTA
    CLRF    PORTB	// Se limpia PORTB
    CLRF    PORTC	// Se limpia PORTC
    CLRF    PORTD	// Se limpia PORTD
    CLRF    PORTE	// Se limpia PORTE
    MOVLW   00111111B	// Mover la literal a W
    MOVWF   PORTC	// Asignar valor de W (0) al display
    CLRF    CONT1	// Se limpia variable CONT1
    CLRF    CONT2	// Se limpia variable CONT2
    
    RETURN
    
CONFIGRELOJ:
    BANKSEL OSCCON  // Direccionamiento al banco 01
    BSF OSCCON, 0   // SCS en 1, se configura a reloj interno
    BSF OSCCON, 6   // bit 6 en 1
    BCF OSCCON, 5   // bit 5 en 0
    BSF OSCCON, 4   // bit 4 en 1
    // Frecuencia interna del oscilador configurada a 2MHz
    RETURN   
    
CONFIGTIMER0:
    BANKSEL OPTION_REG	// Direccionamiento al banco 01
    BCF OPTION_REG, 5	// TMR0 como temporizador
    BCF OPTION_REG, 3	// Prescaler a TMR0
    BSF OPTION_REG, 2	// bit 2 en 1
    BSF	OPTION_REG, 1	// bit 1 en 1
    BSF	OPTION_REG, 0	// bit 0 en 1
    // Prescaler en 256
    // Sabiendo que N = 256 - (T*Fosc)/(4*Ps) -> 256-(0.1*2*10^6)/(4*256) = 60.68 (61 aprox)
    BANKSEL TMR0	// Direccionamiento al banco 00
    MOVLW 61		// Cargar literal en el registro W
    MOVWF TMR0		// Configuración completa para que tenga 100ms de retardo
    BCF T0IF		// Se limpia la bandera de interrupción
    
    RETURN

SUMACONT1:
    BTFSC   PORTA, 0	// Analiza RA0 si no está presionado salta una linea
    GOTO    $-1		// Se mantiene en bucle hasta que se deje de presionar
    INCF    CONT1	// Incremento en 1 la variable del contador
    MOVF    CONT1,W	// Se mueve el valor del contador a W
    CALL    TABLA	// Se llama la subrutina TABLA para buscar el valor de la variable en ASCII
    MOVWF   PORTC	// Se mueve el valor ASCII al display de PORTC
    
    RETURN

RESTACONT1:
    BTFSC   PORTA, 1	// Analiza RA0 si no está presionado salta una linea
    GOTO    $-1		// Se mantiene en bucle hasta que se deje de presionar
    DECF    CONT1	// Disminución en 1 en el contador
    MOVF    CONT1,W	// Se mueve el valor del contador a W
    CALL    TABLA	// Se llama la subrutina TABLA para buscar el valor de la variable en ASCII
    MOVWF   PORTC	// Se mueve el valor ASCII al display de PORTC
    
    RETURN
    
CONTTIMER0:
    BTFSS   T0IF	// Verificación de interrupcion del TMR0
    GOTO    $-1		// Si está en 0 se mantiene en loop hasta que se prenda.
    CALL    RESETTIMER0	// Se llama a la rutina Reset del TMR0
    INCF    PORTB	// Incrementa en 1 el PORTB
    INCF    CONT2	// Incrementa en 1 la variable del contador 2
    BTFSS   CONT2, 1	// Si el 2 bit es 1 saltar a la siguiente linea
    RETURN		// Si no es 1 regresar a main
    BTFSS   CONT2, 3	// Si el 4 bit es 1 saltar a la siguiente linea
    RETURN		// Si no es 1 regresar a main
    INCF    PORTD	// Incrementar en 1 el PORTD
    CLRF    CONT2	// Limpiar la variable usada para la repetición de 10 -> 100mS
    
    RETURN

RESETTIMER0:
    BANKSEL TMR0	// Direccionamiento al banco 00
    MOVLW   61		// Cargar literal en el registro W
    MOVWF   TMR0	// Configuración completa para que tenga 100ms de retardo
    BCF	    T0IF	// Se limpia la bandera de interrupción
    
    RETURN

COMPARACION:
    MOVF    CONT1, W	// Se mueve el valor del PORTC a W
    SUBWF   PORTD, W	// Se resta W a PORTD
    BTFSC   ZERO	// Verificación de la bandera ZERO
    CALL    LEDCERO	// Se llama la subrutina led cero que compara ambos resultados
    
    RETURN

LEDCERO:
    CLRF    CONT2	// Se limpia la variable de la repeticiónde 10 -> 100 ms
    CLRF    PORTD	// Se limpia el contador de segundos
    // Se limpian ambas para que empiecen desde cero sin que existan alguna repetició
    INCF    PORTE	// Incrementar en 1 el PORTE
    
    RETURN

ORG 200h
TABLA:
    CLRF    PCLATH	// Se limpia el registro PCLATH
    BSF	    PCLATH, 1	
    ANDLW   0x0F	// Solo deja pasar valores menores a 16
    ADDWF   PCL		// Se añade al PC el caracter en ASCII del contador
    RETLW   00111111B	// Return que devuelve una literal a la vez 0
    RETLW   00000110B	// Return que devuelve una literal a la vez 1
    RETLW   01011011B	// Return que devuelve una literal a la vez 2
    RETLW   01001111B	// Return que devuelve una literal a la vez 3
    RETLW   01100110B	// Return que devuelve una literal a la vez 4
    RETLW   01101101B	// Return que devuelve una literal a la vez 5
    RETLW   01111101B	// Return que devuelve una literal a la vez 6
    RETLW   00000111B	// Return que devuelve una literal a la vez 7
    RETLW   01111111B	// Return que devuelve una literal a la vez 8
    RETLW   01101111B	// Return que devuelve una literal a la vez 9
    RETLW   01110111B	// Return que devuelve una literal a la vez A
    RETLW   01111100B	// Return que devuelve una literal a la vez b
    RETLW   00111001B	// Return que devuelve una literal a la vez C
    RETLW   01011110B	// Return que devuelve una literal a la vez d
    RETLW   01111001B	// Return que devuelve una literal a la vez E
    RETLW   01110001B	// Return que devuelve una literal a la vez F   
END