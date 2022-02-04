; --------------------------------------------------
; PLANTILLAS

(deftemplate servidor
  (slot hostname)
  (slot os)
  (slot cpd)
  (slot nagios)
  (slot estado)
  (slot conectividad)
  (slot temperatura_server)
  (multislot red))

(deftemplate cpd
  (slot name)
  (slot numero_pcs)
  (slot temperatura)
  (slot contador))

; --------------------------------------------------
; HECHOS INICIALES DEFAULT

(deffacts main_facts

  ;-- Hecho del Main.
  (inicio)

  (servidor
  (hostname PCOscar) 
  (os linux)
  (cpd cpd2)
  (nagios yes)
  (estado off)
  (conectividad on)
  (temperatura_server 32)
  (red 192.168.1.100 32))

  (servidor
  (hostname PCAiran) 
  (os linux)
  (cpd cpd2)
  (nagios yes)
  (estado off)
  (conectividad on)
  (temperatura_server 36)
  (red 192.168.1.101 32))

  (cpd
  (name cpd2)
  (numero_pcs 2)
  (temperatura 22)
  (contador 0))

  (cpd
  (name cpd1)
  (numero_pcs 0)
  (temperatura 19)
  (contador 0))
)

; --------------------------------------------------
; DEFINIMOS REGLAS

; ___INICIO-MENU___
(defrule menu
  (inicio)
  =>
  (printout t "
  ___   _      ___   _      ___   _      ___   _
 [(_)] |=|    [(_)] |=|    [(_)] |=|    [(_)] |=|
  '-`  |_|     '-`  |_|     '-`  |_|     '-`  |_|
 /mmm/  /     /mmm/  /     /mmm/  /     /mmm/  /
   |____________|____________|____________|
                |            |            |
           ___  \_      ___  \_      ___  \_
          [(_)] |=|    [(_)] |=|    [(_)] |=|
           '-`  |_|     '-`  |_|     '-`  |_|
          /mmm/        /mmm/        /mmm/

    ..:: Bienvenido a la Gestión de CPD's ::..
      
      [1] Crear un servidor y añadirlo a un CPD.
      [2] Mostrar información del CPD.
      [3] Salir.

	" crlf)
  (bind ?opcion (read))
  (printout t "La opcion seleccionada es: "?opcion crlf)
  (if (= ?opcion 1) then (assert (add)))
  (if (= ?opcion 2) then (assert (print)))
  (if (eq ?opcion 3) then (printout t "Hasta la próxima!!" crlf) (halt))
)
;___FIN-MENU___


;__ADD-SERVER__
(defrule addserver
  (add)
  ?hecho2<-(add)
  =>
  (printout t "Ha seleccionado añadir un servidor." crlf)
  (printout t "Inserte el hostname: " crlf)
  (bind ?hostname (read))
  (printout t "Inserte el sistema operativo: " crlf)
  (bind ?os (read))
  (printout t "Inserte el cpd perteneciente: " crlf)
  (bind ?cpd (read))
  (printout t "¿Desea controlarlo con el nagios? (yes / no): " crlf)
  (bind ?nagios (read))
  (printout t "¿Estado del servidor? (on / off): " crlf)
  (bind ?estado (read))
  (printout t "¿Tiene conectividad de red? (on / off): " crlf)
  (bind ?conectividad (read))
  (bind ?temperatura_server (random 20 40)) ; Generamos la temperatura aleatoriamente.
  (printout t "Inserte los datos de red (0.0.0.0 32): " crlf)
  (bind ?red (readline)) ; cogemos toda la linea.

  (assert (servidor
    (hostname ?hostname)
    (os ?os)
    (cpd ?cpd)
    (nagios ?nagios)
    (estado ?estado)
    (conectividad ?conectividad)
    (temperatura_server ?temperatura_server)
    (red ?red)
  ))

  (assert (addhostcpd))
  (assert (aux ?cpd))
  (printout t "
	Se ha creado el servidor "?hostname" y se ha añadido al "?cpd crlf)
  (retract ?hecho2) ; Eliminamos el hecho add.
)

(defrule addhostcpdserver
  (addhostcpd)
  (aux ?n)
  (cpd (name ?n)(numero_pcs ?n_pcs))
  ?hecho3<-(cpd (name ?n))
  ?hecho5<-(addhostcpd)
  =>
  (bind ?n_pcs (+ ?n_pcs 1))
  (modify ?hecho3(numero_pcs ?n_pcs))
  (retract ?hecho5) ; Eliminamos el hecho addhostcpd.
)

(defrule PrintCPD
  (print)
  (cpd (name ?a)(numero_pcs ?b)(temperatura ?c)(contador ?d))
  =>
  (printout t "Nombre CPD:"?a", nºserver:"?b", temperatura:"?c crlf)
  (assert (printh))
)

(defrule delPrintCPD
  (print)
  ?hecho6<-(print)
  =>
  (retract ?hecho6) ; Eliminamos el hecho print.
)


(defrule TemperaturaPC "imprime los equipos que superan la temperatura"
  (servidor (hostname ?nom) (temperatura_server ?temp))(test (>= ?temp 30)) 
  =>
  (printout t "Los equipos con Temperatura >= 30º son: "?nom crlf)
)

(defrule AlarmaPC "imprime los equipos que se encuentran apagados o sin conectividad"
  (or

  (servidor (hostname ?nom)
  (nagios yes)
  (estado off))

  (servidor (hostname ?nom)
  (nagios yes)
  (conectividad off)))
  =>
  (printout t "Los equipos con algun aviso son: "?nom crlf)
)

(defrule AlarmaCPD "Se envia SMS si salta la alarma"
  (cpd (name ?nam)
  (temperatura ?temp))
  =>
  (if (>= ?temp 20)
    then
    (printout t "SMS - Alarma en: " ?nam crlf))
)

(defrule AvisoContadorCPD
  (or
 
  (servidor (hostname ?hname)(cpd ?Ncpd)
  (estado off))

  (servidor (hostname ?hname)(cpd ?Ncpd)
  (conectividad off)))
  =>
  (bind ?counter 0)
  (do-for-all-facts ((?Namecpd cpd))
    (eq ?Namecpd:name ?Ncpd)
    (bind ?counter (+ ?counter 1))
  )
  (if (>= ?counter 1)
    then
    (printout t "El servidor:"?hname", ha fallado en el CPD:"?Ncpd crlf)
  )
)

(defrule reset_main
  ?hecho1<-(inicio)
  =>
  (retract ?hecho1)
  (assert (inicio))
)
