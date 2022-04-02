 
#include <stdio.h>
#include <string.h>

#include <webots/distance_sensor.h>
#include <webots/motor.h>
#include <webots/robot.h>
#include <webots/camera.h>

#ifdef _WIN32
#include <winsock.h>
#else
#include <arpa/inet.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#endif

#define SOCKET_PORT 9877
#define SOCKET_SERVER "127.0.0.1" /* local host */
#define TIME_STEP 16
#define UNKNOWN 99999.99
#define FILTER_SIZE 3



int main(int argc, char **argv) {
  /////////////parameters//////////////////////////
  struct sockaddr_in address;
  struct hostent *server;
  int fd, rc;
  char buffer[2048];
  //char * buffer = (char*) malloc(sizeof(char) * 1035);
  //double steering_angle = 0.0;
  double speed = 5.0;
  WbDeviceTag camera;
  //int width = -1;
  //int height = -1;
  //double camera_fov = -1.0;

  wb_robot_init();
////////////parameters////////////////////////////////
/////////////////////socket///////////////////////////////
#ifdef _WIN32
  /* initialize the socket api */
  WSADATA info;

  rc = WSAStartup(MAKEWORD(1, 1), &info); /* Winsock 1.1 */
  if (rc != 0) {
    printf("cannot initialize Winsock\n");

    return -1;
  }
#endif
  /* create the socket */
  fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd == -1) {
    printf("cannot create socket\n");
    return -1;
  }

  /* fill in the socket address */
  memset(&address, 0, sizeof(struct sockaddr_in));
  address.sin_family = AF_INET;
  address.sin_port = htons(SOCKET_PORT);
  server = gethostbyname(SOCKET_SERVER);

  if (server)
    memcpy((char *)&address.sin_addr.s_addr, (char *)server->h_addr, server->h_length);
  else {
    printf("cannot resolve server name: %s\n", SOCKET_SERVER);
#ifdef _WIN32
    closesocket(fd);
#else
    close(fd);
#endif
    return -1;
  }

  /* connect to the server */
  rc = connect(fd, (struct sockaddr *)&address, sizeof(struct sockaddr));
  if (rc == -1) {
    printf("cannot connect to the server\n");
#ifdef _WIN32
    closesocket(fd);
#else
    close(fd);
#endif
    return -1;
  }

  ////////////////////socket end///////////////////////////////////////
  ///////////////////initialize////////////////////////////
  int i;
  //bool avoid_obstacle_counter = 0;
  WbDeviceTag ds[2];
  char ds_names[2][10] = {"ds_left", "ds_right"};
  for (i = 0; i < 2; i++) {
    ds[i] = wb_robot_get_device(ds_names[i]);
    wb_distance_sensor_enable(ds[i], TIME_STEP);
  }
  /* Get the camera device, enable it, and store its width and height */
  camera = wb_robot_get_device("camera");
  
  wb_camera_enable(camera, TIME_STEP);
 
  //width = wb_camera_get_width(camera);
  //height = wb_camera_get_height(camera);
  //camera_fov = wb_camera_get_fov(camera);
  
  WbDeviceTag wheels[4];
  char wheels_names[4][8] = {"motor1", "motor2", "motor3", "motor4"};
  for (i = 0; i < 4; i++) {
    wheels[i] = wb_robot_get_device(wheels_names[i]);
    wb_motor_set_position(wheels[i], INFINITY);
  }
  double left_speed = speed;
  double right_speed = speed;
//////////////////////////////initialize//////////////////////////////////////////////
//////////////////////////////send/receive data /////////////////////////////////////

  while (wb_robot_step(TIME_STEP) != -1) {
  //wb_robot_step(TIME_STEP);
    char seperate =':';
    //char end = ';';

    int ds_values[2];
    ds_values[0] = wb_distance_sensor_get_value(ds[0]);
    ds_values[1] = wb_distance_sensor_get_value(ds[1]);

    double time = wb_robot_get_time(); 
    
    //int i=0;
    const unsigned char *image = wb_camera_get_image(camera);
    //int z= 0;
    
    /*for (int x = 0; x <= 15; x++){
      for (int y= 0; y<= 15; y++){
        printf("%d %d %d ",(int) image[z+2],(int) image[z+1],(int) image[z]);
        z=z+4;
      }
      printf("\n");
    }*/
    
    
    
    i = sprintf(buffer, "%d%c%d%c%f%c%s;",ds_values[0],seperate,ds_values[1],seperate,time,seperate,image);
   
    //sprintf(buffer, "%s;",image);
    //printf("Länge %lu \n", strlen((char*)image));
/*
    const unsigned char *image = wb_camera_get_image(camera);
    for(int x = 0; x < width; x++){
      for(int y = 0; y < height; y++){
        buffer[i]=(unsigned char)wb_camera_image_get_blue(image, width, x, y);
        ++i;
        buffer[i]=(unsigned char)wb_camera_image_get_green(image, width, x, y);
        ++i;
        buffer[i]=(unsigned char)wb_camera_image_get_red(image, width, x, y);
        ++i;
      }
    }*/
    
    
    
    
    
    //buffer[i] = end;
    //printf("Länge %lu \n", strlen(buffer));

    if(write(fd,buffer,strlen(buffer)) < 0)       {
            perror("writing on stream socket");
            exit(1);
        }

    recv(fd, buffer, 256, 0);
    sscanf(buffer, "%lf:%lf", &left_speed, &right_speed);
    
    //printf("%lf , %lf \n", left_speed, right_speed);

    
    wb_motor_set_velocity(wheels[0], left_speed);
    wb_motor_set_velocity(wheels[1], right_speed);
    wb_motor_set_velocity(wheels[2], left_speed);
    wb_motor_set_velocity(wheels[3], right_speed);
  }
  wb_robot_cleanup();
  
  return 0;  // EXIT_SUCCESS
}
