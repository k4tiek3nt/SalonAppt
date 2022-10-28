#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

# name of salon
echo -e "\n~~~~~ MY SALON ~~~~~\n"

# greeting before listing available services
echo -e "Welcome to My Salon, how can I help you?\n"

#begin main menu function to list available services
MAIN_MENU() {
  # get services from services table
  AVAILABLE_SERVICES=$($PSQL "SELECT * FROM services ORDER BY service_id;")
  
  # list services
  echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done
  
  # get customer selection
  read SERVICE_ID_SELECTED

  # confirm service_id is valid and start creating appointment for selected choice
  
  case $SERVICE_ID_SELECTED in
    1) CREATE_APPT;; # cut
    2) CREATE_APPT;; # color
    3) CREATE_APPT;; # perm
    4) CREATE_APPT;; # style
    5) CREATE_APPT;; # trim
    *) echo -e "\nI could not find that service. What would you like today?";;
  esac

  # send back to main menu if not a valid choice
  MAIN_MENU
}

# beginning of appointment
CREATE_APPT(){
  
  #get customer phone number
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # get customer_id
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE';")

  # if customer_id doesn't exist
  if [[ -z $CUSTOMER_ID ]]
  then
    # get customer name
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    
    # insert customer info into customers table
    CUSTOMER_INSERT_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
    
    # if customer is sucessfully added
    if [[ $CUSTOMER_INSERT_RESULT == "INSERT 0 1" ]]
    then
      # reattempt to get customer_id
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE';")
    fi
    # if customer is not sucessfully added
    if [[ $CUSTOMER_INSERT_RESULT != "INSERT 0 1" ]]
    then
    # send to main menu
      echo -e "\nSomething went wrong, please try again $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
      MAIN_MENU 
    fi
  fi

  # get service name based on selected service
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED;") 
  
  # if customer exists, get name based on phone number
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE';")

  # if / when customer exists, get service time
  echo -e "\nWhat time would you like your $(echo $SERVICE_NAME | sed -E 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -E 's/^ *| *$//g')?"
  read SERVICE_TIME

  # add appointment to appointments table
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
  
  # exit the appointment creation if successfully added to appointments table
  if [[ $INSERT_APPOINTMENT_RESULT == "INSERT 0 1" ]]
  then
  # confirm appointment and exit program
    echo -e "\nI have put you down for a $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g') at $SERVICE_TIME, $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
    echo -e "Thank you for stopping in."
    exit
  fi
  
  # send to main menu if doesn't succefully add
  if [[ $INSERT_APPOINTMENT_RESULT != "INSERT 0 1" ]]
  then
    echo -e "\nSomething went wrong, please try again $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
    MAIN_MENU
  fi    
}

# begin program, listing available services
MAIN_MENU