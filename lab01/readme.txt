Che cos'è
File di configurazione per il simulatore ARGoS (ARGOS3). Definisce l'esperimento: robot, sensori/attuatori, arena, motore fisico e visualizzazione.

Framework
- system threads="0": numero di thread (0 = autodetect).
- experiment length="0": durata in tick (0 = infinito). ticks_per_second regola la scala temporale.
- random_seed (opzionale) per riproducibilità.

Controllers
- lua_controller id="lua": usa uno script Lua per il comportamento.
- actuators: differential_steering, leds (con parametri di rumore/visualizzazione).
- sensors: proximity, light, motor_ground, positioning (fake, giusto per debugging), ecc.
- params script="hellorobot.lua": file Lua collegato che implementa il controllo del robot.

Arena
- size e center: dimensioni dell'arena in metri.
- floor: texture immagine (four_spots.png).
- box: muri/ostacoli con posizione e dimensioni.
- light: sorgente luminosa collegata al medium "leds".
- distribute: posiziona oggetti e robot casualmente (qui 5 box e 1 foot-bot). Sezione commentata per posizionamento preciso.

Physics engines
- dynamics2d: motore fisico 2D usato per la simulazione.

Media
- led id="leds": definizione del medium usato per luci/LED.

Visualization
- qt-opengl: interfaccia 3D con impostazioni delle camere (placement).

Note pratiche
- Modificare hellorobot.lua per cambiare il comportamento del robot.
- Avviare simulazione (se argos3 installato):
  argos3 -c /home/diego/robotic/lab/lab01/hellorobot.argos
- Impostare length>0 per terminare automaticamente; usare random_seed per esperimenti riproducibili.