#$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
#$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), 'cataclysm_utility'))
require "base64"
require "json"
require "fileutils"
require "English"

require_relative "cataclysm_vehicle"
require_relative "cataclysm_world" 
require_relative "cataclysm_character"
require_relative "ui" 

class CataclysmManager

  def initialize()
    @world_tracker = scan_for_worlds()
  end
  
  def each_world
    # iterator for worlds
    @world_tracker.each do |name, world_object|
      yield(name, world_object)
    end
    return self
  end
   
  def scan_for_worlds()
    # validate that we're in something resembling a CDDA game directory
    if Dir.exist?("save")
      savegame_list = Dir.entries("save")
      # delete all non-savegame entries from our list of saves
      savegame_list.delete(".")
      savegame_list.delete("..")
    else
      UI.display("Couldn't find a save directory, a few things could be wrong.", true)
      UI.display("Are we inside the Cataclysm:DDA folder? Was it just installed and never run?", true)
      UI.display("Our current directory is #{Dir.pwd}", true)
      exit(1)
    end
    # load all worlds and characters in the game directory
    world_hash = Hash.new
    savegame_list.each do |world|
      world_hash[world] = CataclysmWorld.new(world)
    end
    return world_hash
  end
  
  def [](name)
    return @world_tracker[name]
  end
  
  def copy_char
    # handles the action of copying character
    UI.display("Copying/moving/renaming/backing-up a character.")
    UI.print_character_directions
    desired_world = UI.pick_a_world(self)
    character_ref = UI.pick_a_character(desired_world)
    UI.display("Pick a target world to copy #{character_ref.name} to:")
    target_world = UI.pick_a_world(self)
    UI.display("Choose target character in #{target_world.name}, we will move to their position.")
    target_pos = UI.pick_a_character(target_world).get_pos
    UI.display("Now we need a new character name for the copied character.")
    character_ref.save_me(UI.get_input("Enter new character name"), target_world.name, target_pos)
  end
  
  def copy_world
    UI.display("Copying/renaming/backing-up a world.")
    UI.pick_a_world(self).save_me(UI.get_input("To where?"))
  end
  
  def copy_vehicle
    UI.display("Copying a vehicle between worlds.")
    UI.print_vehicle_directions
    source_vehicle = UI.pick_a_world(self).grab_vehicle(UI.get_vehicle_input("Source"))
    UI.pick_a_world(self).replace_vehicle(UI.get_vehicle_input("Destination"), source_vehicle)
  end
  
  def save_vehicle
    Dir.mkdir("./saved_vehicles") unless Dir.exist?("./saved_vehicles")
    UI.display("Saving vehicle to a JSON file (.json), in ./saved_vehicles")
    source_vehicle = UI.pick_a_world(self).grab_vehicle(UI.get_vehicle_input("Source"))
    source_vehicle.save_to_file("./saved_vehicles/" + UI.get_input("Enter a name for the saved vehicle:"))
  end
  
  def load_vehicle 
    UI.display("Loading vehicle from JSON files (.json) in ./saved_vehicles")
    UI.print_vehicle_directions
    UI.display("Pick a vehicle from the ones saved in the Cataclysm directory:")
    list_of_vehicle_jsons = Dir.glob("./saved_vehicles/*#{CataclysmVehicle::VEHICLE_FILENAME_SUFFIX}")
    list_of_vehicle_jsons.each_index do |index|
      # leave off the .json
      UI.display(File.basename(list_of_vehicle_jsons[index], ".json"))
    end
    begin
      v_name = UI.get_input("Enter the name of the saved vehicle to load:")
      UI.display("Couldn't find vehicle by that name.") unless File.exist?("./saved_vehicles/#{v_name}.json")
    end until File.exist?("./saved_vehicles/#{v_name}.json")
    source_vehicle = CataclysmVehicle.load_from_file("./saved_vehicles/#{v_name}.json")
    UI.pick_a_world(self).replace_vehicle(UI.get_vehicle_input("Destination"), source_vehicle)
  end
  
  def delete_char
    UI.display("Deleting a character.")
    target_world = UI.pick_a_world(self)
    target_char = UI.pick_a_character(target_world)
    #target_char = self[target_world].pick_a_character
    target_char.delete_me if UI.get_confirmation_input_prompt("#{target_char.name} in #{target_world.name}")
  end
  
  def delete_world
    UI.display("Deleting a world.")
    target_world = UI.pick_a_world(self)
    target_world.delete_me if UI.get_confirmation_input_prompt(target_world.name)
  end
  
  def do_action(current_action)
    case current_action
    when 1
      UI.print_directions
    when 2
      UI.print_worlds_and_characters(self)
    when 3 # copy/move/backup character
      copy_char
    when 4 # copy a world
      copy_world
    when 5 # copy vehicle between worlds
      copy_vehicle
    when 6 # save vehicle to json
      save_vehicle
    when 7 # load vehicle from json
      load_vehicle
    when 8 # delete character
      delete_char
    when 9 # delete world
      delete_world
    when 10
      UI.print_vehicle_names(UI.pick_a_world(self))
    else
      UI.display("Unknown input.")
    end
  end

end