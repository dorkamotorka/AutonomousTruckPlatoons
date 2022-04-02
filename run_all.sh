#!/bin/bash

# Run Python Backend
cd backend/tcp_server/scripts
gnome-terminal --tab -- python3 tcp_server_backend.py
cd ../../..
sleep 5

# Run Frontend
cd frontend
gnome-terminal --tab -- python3 app.py
sleep 2
gnome-terminal --tab -- npm run start
cd ..

# Run External Controller
cd external_controller 
gnome-terminal --tab -- ./obj/main 9001 
sleep 1
gnome-terminal --tab -- ./obj/main 9002
sleep 1
gnome-terminal --tab -- ./obj/main 9003
sleep 1
gnome-terminal --tab -- ./obj/main 9004
sleep 1
gnome-terminal --tab -- ./obj/main 9005 
cd ..

# Run Webots
cd webots/worlds
gnome-terminal --tab -- webots enviroment_final_5T.wbt 
cd ../..
