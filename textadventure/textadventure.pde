// TEXT ADVENTURE GAME
// Made by Ben in Processing 4

// Import libraries
import processing.sound.*;
import processing.net.*;
import java.util.Arrays;

// Define variables
String textInput = "";
String output = "";
int outputTimer = 0;
PFont font;
Table roomData;
TableRow currentRoom;
String roomID = "startingroom";
String textCursor = "|";
int cursorTimer = 0;
String[] inputList;
boolean helpOpen;
boolean invOpen;
SoundFile[] keyboardSounds;
SoundFile footstepSounds;
String[] loadingDots = {".","..","..."};
int loadingDotCount = 0;
int loadingDotTimer = 20;
String[] loadData;
boolean soundsEnabled = true;
boolean cursorEnabled = true;
StringList pickups;
StringList inventory;

// Setup function
void setup() {
  // Screen setup
  size(displayWidth,displayHeight);
  noCursor();
  noStroke();
  surface.setResizable(true);
  surface.setTitle("Text Adventure");
  smooth(8);
  // Load sounds
  thread("loading");
  // Load font
  font = loadFont("monospace.vlw");
  inventory = new StringList();
  // Test for existing savegame
  if (loadStrings("data/save.txt") != null) {
    loadData = loadStrings("data/save.txt");
    roomID = loadData[0];
    inventory = new StringList(split(loadData[2],','));
    if (inventory.get(0).equals("")) {
      inventory.remove(0);
    }
    soundsEnabled = parseBoolean(loadData[1]);
    cursorEnabled = parseBoolean(loadData[3]);
  }
  // Load spreadsheet and get data
  roomData = loadTable("roomData.csv","header");
  if (loadTable("data/roomDataSaved.csv","header") != null) {
    roomData = loadTable("data/roomDataSaved.csv", "header");
  }
  saveTable(roomData, "data/roomDataSaved.csv");
  currentRoom = roomData.findRow(roomID, "ID");
  // Setup text and background
  background(0);
  textFont(font);
  textSize(20);
}

// Draw function
void draw() {
  // Loading screen
  if (keyboardSounds[2] == null) {
    background(0);
    fill(255);
    text("Loading" + loadingDots[loadingDotCount],20,height*0.95);
    loadingDotTimer -= 0.5;
    if (loadingDotTimer <= 0) {
      loadingDotCount += 1;
      loadingDotTimer = 30;
      if (loadingDotCount > 2) {
        loadingDotCount = 0;
      }
    }
  } else {
    gameLoop();
  }
}
// Gameloop function
void gameLoop() {
  currentRoom = roomData.findRow(roomID, "ID");
  background(0);
  fill(255);
  if (helpOpen) {
    // Help menu
    text("» Help",20,40);
    text("Type return to go back",20,70);
    text("Commands:",20,130);
    text("help - shows this menu",20,160);
    text("return - exits out of a menu",20,190);
    text("toggle <setting> - toggles a setting (run without params to see list)",20,220);
    text("exit - exit the game",20,250);
    text("go <north|south|east|west> - travel in a direction",20,280);
    text("pickup <object> - pick up an object",20,310);
    text("inventory - view your inventory",20,340);
  } else if (invOpen) {
    // Inventory menu
    text("» Inventory",20,40);
    text("Type return to go back",20,70);
    if (inventory.size() != 0) {
      text("• " + inventory.join(ENTER+"• "),20,130);
    } else {
      text("You are not holding any items",20,130);
    }
  } else {
    // Game menu
    text("» "+currentRoom.getString("Name"),20,40);
    text(currentRoom.getString("Info").replace('/',ENTER),20,100);
  }
  // Command prompt
  text("> "+textInput+textCursor,20,height*0.95);
  fill(150,150,150);
  text(output,20,height*0.95-30);
  fill(255);
  if (cursorEnabled) {
    if (mousePressed) {
      fill(255);
    } else {
      fill(200);
    }
    circle(mouseX,mouseY,8);
  }
  // Blinking cursor
  if (cursorTimer < 0) {
    cursorTimer = 40;
    if (textCursor == "") {
      textCursor = "|";
    } else {
      textCursor = "";
    }
  } else {
    cursorTimer -= 1;
  }
  // Info output timer
  if (outputTimer >= 1) {
    outputTimer -= 1;
  } else {
    output = "";
  }
}

// Keypress function
void keyPressed() {
  if (keyboardSounds[2] != null) {
    // Keyboard sounds
    if(soundsEnabled) {
      keyboardSounds[int(random(0,3))].play(1.0f);
    }
    // Cancel invalid characters
    if (key == ESC || key == TAB || key == CODED) {
      key = 0;
    }
    // Handle backspaces
    else if (key == BACKSPACE) {
      if (textInput.length() != 0) {
        textInput = textInput.substring(0, textInput.length() - 1);
      }
    } 
    // Handle command entry
    else if (key == ENTER) {
      command(textInput);
      textInput = "";
    }
    // Handle regular key input
    else {
      textInput = textInput + key;
      cursorTimer = 40;
    }
  }
}

// Command handling
void command(String input) {
  inputList = split(input.toLowerCase(), " ");
  if (!inputList[0].equals("exit")) {
    output = "";
    outputTimer = 0;
  }
  // Switch case for commands
  switch(inputList[0]) {
    case("help"): case("guide"): case("helpme"): case("wtfamidoing"): case("iamastupidmoronandineedinstructions"):
      if (helpOpen) {
        output = "Somehow, you were already there";
        outputTimer = 100;
        break;
      }
      helpOpen = true;
      invOpen = false;
      break;
    case("return"): case("back"):
      if (!helpOpen && !invOpen) {
        output = "You are not in a menu";
        outputTimer = 100;
      }
      if (helpOpen) {
        helpOpen = false;
      }
      if (invOpen) {
        invOpen = false;
      }
      break;
    case("exit"):
      if (outputTimer <= 0 || output != "Type exit again to exit") {
        output = "Type exit again to exit";
        outputTimer = 150;
      } else {
        background(0);
        fill(255);
        text("Saving game...",20,height*0.95);
        String[] saveData = {roomID, String.valueOf(soundsEnabled), inventory.join(","), String.valueOf(cursorEnabled)};
        saveStrings("data/save.txt", saveData);
        saveTable(roomData, "data/roomDataSaved.csv");
        exit();
      }
      break;
    case("toggle"): case ("switch"):
      if (inputList.length < 2) {
        output = "Avaliable options - sounds, cursor";
        outputTimer = 100;
        break;
      }
      if (inputList[1].equals("sounds") || inputList[1].equals("sound")) {
        soundsEnabled = !soundsEnabled;
        output = "Sound effects set to " + soundsEnabled;
        outputTimer = 100;
        break;
      }
      if (inputList[1].equals("cursor") || inputList[1].equals("mouse")) {
        cursorEnabled = !cursorEnabled;
        output = "Cursor set to " + cursorEnabled;
        outputTimer = 100;
        break;
      }
    case("pickup"): case("grab"): case("get"):
      if (inputList.length < 2) {
        output = "Command usage: pickup <object>";
        outputTimer = 100;
        break;
      }
      pickups = new StringList(split(currentRoom.getString("Pickup"),','));
      if (pickups.hasValue(inputList[1])) {
        output = "You pick up a " + pickups.get(pickups.index(inputList[1]));
        inventory.append(inputList[1]);
        pickups.remove(pickups.index(inputList[1]));
        currentRoom.setString("Pickup",pickups.join(","));
        outputTimer = 100;
        break;
      } else {
        output = "That object isn't in this room!";
        outputTimer = 100;
        break;
      }
    case("inv"): case("inventory"):
      if (invOpen) {
        output = "Somehow, you were already there";
        outputTimer = 100;
        break;
      }
      invOpen = true;
      helpOpen = false;
      break;
    case("go"): case("move"): case("walk"): case("goto"):
      if (roomID.equals("racoon")) {
        output = "There is no escape.";
        outputTimer = 100;
        break;
      }
      if (helpOpen) {
        output = "Type return to go back";
        outputTimer = 100;
        break;
      }
      if (inputList.length < 2) {
        output = "Command usage: go <north|south|east|west>";
        outputTimer = 100;
        break;
      }
      if (inputList[1].equals("west") || inputList[1].equals("w")) {
        if (roomData.findRow(currentRoom.getString("West Room"), "ID") == null) {
          output = "You can not go that direction!";
          outputTimer = 100;
        } else {
          roomID = currentRoom.getString("West Room");
          if(soundsEnabled) {
            footstepSounds.play(1f);
          }
        }
      }
      else if (inputList[1].equals("east") || inputList[1].equals("e")) {
        if (roomData.findRow(currentRoom.getString("East Room"), "ID") == null) {
          output = "You can not go that direction!";
          outputTimer = 100;
        } else {
          roomID = currentRoom.getString("East Room");
          if(soundsEnabled) {
            footstepSounds.play(1f);
          }
        }       
      }
      else if (inputList[1].equals("north") || inputList[1].equals("n")) {
        if (roomData.findRow(currentRoom.getString("North Room"), "ID") == null) {
          output = "You can not go that direction!";
          outputTimer = 100;
        } else {
          roomID = currentRoom.getString("North Room");
          if(soundsEnabled) {
            footstepSounds.play(1f);
          }
        }
      }
      else if (inputList[1].equals("south") || inputList[1].equals("s")) {
        if (roomData.findRow(currentRoom.getString("South Room"), "ID") == null) {
          output = "You can not go that direction!";
          outputTimer = 100;
        } else {
          roomID = currentRoom.getString("South Room");
          if(soundsEnabled) {
            footstepSounds.play(1f);
          }
        }
      } else {
        output = "Command usage: go <north|south|east|west>";
        outputTimer = 100;
      }
      break;
    case(""):
      output = "Please enter a command";
      outputTimer = 100;
      break;
    case("upupdowndownleftrightleftrightba"): case("upupdowndownleftrightleftrightbastart"):
      output = "Cheat code activated";
      outputTimer = 100;
      break;
    case("amongus"): case("amogus"): // AMONG US REFERENCE?!?!?!
      output = "sus";
      outputTimer = 100;
      break;
    case("sus"): case("sussy"): // ANOTHER AMONG US REFERENCE?!?!?!
      output = "amongus";
      outputTimer = 100;
      break;
    case("racoon"): // Racoon.
      roomID = "racoon"; // Racoon.
      output = "Racoon"; // Racoon.
      outputTimer = 100; // Racoon.
      break; // Racoon.
    default:
      if (helpOpen) {
        output = "Type return to go back";
        outputTimer = 100;
        break;
      }
      if (input.toLowerCase().equals("this was a triumph")) {
        output = "I'm making a note here, 'HUGE SUCCESS'"; // You monster.
        outputTimer = 100;
        break;
      }
      output = "Invalid command";
      outputTimer = 100;
      break;
  }
}

// Load sounds
void loading() {
  keyboardSounds = new SoundFile[3];
  footstepSounds = new SoundFile(this, "footsteps.mp3");
  for (int i = 0; i < 3; i++) {
    keyboardSounds[i] = new SoundFile(this, (i+1) + ".mp3");
  }
}
