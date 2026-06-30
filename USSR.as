// Documentation available at https://donadigo.com/tminterface/plugins/api
// Also want a random 64 bit number, cause its possible that the state with that name already exists
// that random number will essentially be my session id ig.
// Can potentially create an import-export mechanic using that in the future

// Ok however, if they quit the map and rejoin, should we reset the savestates thing?
// I suppose not, stays in same session.
// So maybe a whole reset savestates command too.


class StateStringStore {
    string pre;
    string post;


    StateStringStore() {
        this.pre = "";
        this.post = "";
    }

    StateStringStore(string pre, string post) {
        this.pre = pre;
        this.post = post;
    }
}

// List of states files
array<StateStringStore> states_list;
// Is the index of the current state in the states_list
int current_state = -1;
// Tracks the current state created, for file naming reasons
int states_tracker = 0;

// The uid for the session. Keeps the states in different sessions from overwriting each other.
int uid;



void printStateList() {
    string state_list_string = "[";

    for (uint i = 0; i < states_list.get_Length(); i++) {
        state_list_string += "{" + states_list[i].pre + ", " + states_list[i].post + "}";
        
        if (i < states_list.get_Length() - 1) {
            state_list_string += ", ";
        }
    }
    state_list_string += "]";

    log("Statelist: "+ state_list_string);
}


// Saves the current state of game into a file
void saveState(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    SimulationManager@ simManager = GetSimulationManager();
    string error;
    SimulationStateFile f;
    f.CaptureCurrentState(simManager, true);
    
    TM::GameCtnChallenge@ map = GetCurrentChallenge();
    if (map is null) {
        log("Not in a race!");
        return;
    }

    string new_pre_name = map.get_Name()+"_"+float(simManager.get_RaceTime())/1000+"_"+uid;


    // the new naming convention, suggested by one of my friends
    // format: depth-statecount_parent
    // So each file tracks its parent, so you know what its previous state is.
    string new_post_name = "";

    if (current_state == -1) {
        // The starting state
        states_tracker += 1;
        new_post_name = "1-1_0";
    } else {
        // new naming convention
        // tracks the parent.
        states_tracker += 1;
        string current_state_post = states_list[current_state].post;
        string current_state_post_data = current_state_post.Split("-")[1];
        string current_state_index = current_state_post_data.Split("_")[0];
        states_list.Resize(current_state+1);
        new_post_name = (states_list.get_Length()+1)+"-"+states_tracker+"_"+current_state_index;
    }
    states_list.Add(StateStringStore(new_pre_name, new_post_name));

    
    // This is the old naming convention idea
    // the idea was: 
    /**
    state 1: 1, state 2 is 2, state 3 is 3, state 4 is 4, state 5 is 5
    If we go back to 3, and start again, the new state will be called 4.1_1, 
    and making new states after that will make 4.1_2, 4.1_3, and so on. 
    The things after _ are now thought of as the counter.

    If i go back to state 3, and again start making new states, they would then be called 4.2_1, and so on
    Suppose i was at state 4.2_6, and then 4.2_7, but went back to 4.2_6 to retry the enxt state, 
    it would then be called 4.2_7.1_1, and so on
    */
    // If you like the below naming convention, feel free to uncomment below, and omment the above naming convention
    // It does work

    // if (!(current_state == int(states_list.get_Length())-1)) {
    //     // If the current state is not at the end, we need to change the alt counting earlier, and remove the later stuff

    //     // Changing of letters
    //     // array = array[0:current+2]
    //     // I want this states list to have 
    //     states_list.Resize(current_state+2);
    //     string one_after_current_post = states_list[current_state+1].post;
    //     array<string> one_after_current_post_split = one_after_current_post.Split("_");

    //     string final_post_name;
    //     // The last one is always a pure integer
    //     if ((one_after_current_post_split[one_after_current_post_split.get_Length()-1]) == "0") {
    //         // Case of 1.2_3.4_5, 1.2_3.4_6.3_0
    //         // Change to 1.2_3.4_5, 1.2_3.4_6.4_0

    //         string iteration = one_after_current_post_split[one_after_current_post_split.get_Length()-2];
    //         // iteration is something like 6.3
    //         array<string> iterations = iteration.Split(".");
    //         string new_iteration = iterations[0]+"."+(Text::ParseInt(iterations[1])+1)+"_0";

    //         one_after_current_post_split.Resize(one_after_current_post_split.get_Length()-2);
    //         one_after_current_post_split.Add(new_iteration);
    //         final_post_name = Text::Join(one_after_current_post_split, "_");
    //     } else {
    //         // Case of 1.2_3.4_5, 1.2_3.4_6
    //         // Change to  1.2_3.4_5, 1.2_3.4_6.1_1
    //         string new_iteration = (one_after_current_post_split[one_after_current_post_split.get_Length()-1])+".1_0";

    //         one_after_current_post_split.Resize(one_after_current_post_split.get_Length()-1);
    //         one_after_current_post_split.Add(new_iteration);
    //         final_post_name = Text::Join(one_after_current_post_split, "_");
    //     }

    //     states_list[current_state+1] = StateStringStore(new_pre_name, final_post_name);
    // } else {
    //     if (current_state == -1) {
    //         states_list.Add(StateStringStore(new_pre_name, "0"));
    //     } else {
    //         string current_post_name = states_list[current_state].post;
    //         array<string> post_names_data = current_post_name.Split("_");

    //         string new_post_post_name = ""+(Text::ParseInt(post_names_data[post_names_data.get_Length()-1])+1);
    //         post_names_data.RemoveAt(post_names_data.get_Length()-1, 1);
            
    //         post_names_data.Add(new_post_post_name);
    //         string new_post_name = Text::Join(post_names_data, "_");

    //         states_list.Add(StateStringStore(new_pre_name, new_post_name));
    //     }
    // }
    current_state += 1;
    // printStateList();

    if (!f.Save(states_list[current_state].pre+"_"+states_list[current_state].post+".bin", error)) {
        // Handle error
        log(error);
    }
    log("Saved: "+states_list[current_state].pre+"_"+states_list[current_state].post);

}



// restores the current state. The current can be changed.
void loadState(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    if (int(states_list.get_Length()) <= current_state) {
        // Throw error? We should not be able to reach here? Oh well ig can.
        return;
    }

    string error;
    SimulationStateFile f;
    StateStringStore current_statename = states_list[current_state];
    if (!f.Load(current_statename.pre+"_"+current_statename.post+".bin", error)) {
        log(error);
        // Handle error
    }

    SimulationManager@ simManager = GetSimulationManager();
    // Restore the full file with inputs and previous states
    simManager.RewindToState(f);
    log("Loaded: "+states_list[current_state].pre+"_"+states_list[current_state].post);

}

// go to previous state
void prevState(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    if (current_state > 0) current_state -= 1;
    loadState(fromTime, toTime, commandLine, args);
}

/** Goes to the next state*/
void nextState(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    if (current_state < int(states_list.get_Length())-1) current_state += 1;
    loadState(fromTime, toTime, commandLine, args);
}

// Clears the current states list
// Also, keep a backup?, if someone accidentally runs resets_states
// Maybe in next update, will have to think how to manage
// Or maybe log the previous states list, or both!
// Should also reset the random number.
// And set current_state to -1
void resetStates(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    // TODO: Call exportStates to print it in console, as a backup
    states_list.Clear();
    current_state = -1;
    uid = Math::Rand(0, 2147483647);
}


// Export and Import are relatively easy??
// Just give the random number, and the arraylist thats it!
// Dont even need to give the random num then? Should be inferable? Maybe not oh well.
// Also ig current state?
// Also states tracker
void exportStates(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    dictionary export_dict;
    export_dict.Set("uid", uid);
    export_dict.Set("current_state", current_state);
    export_dict.Set("states_tracker", states_tracker);
    // Need to convert array of StateStringStore to two arrays of strings, one for pre and one for post
    array<string> pre_list;
    array<string> post_list;
    for (uint i = 0; i < states_list.get_Length(); i++) {
        pre_list.Add(states_list[i].pre);
        post_list.Add(states_list[i].post);
    }

    export_dict.Set("states_list_pre", pre_list);
    export_dict.Set("states_list_post", post_list);

    // Should export as a file too maybe? Not sure
    print(toJson(export_dict));
}

void logStates (int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    dictionary export_dict;
    export_dict.Set("uid", uid);
    export_dict.Set("current_state", current_state);
    export_dict.Set("states_tracker", states_tracker);
    // Need to convert array of StateStringStore to two arrays of strings, one for pre and one for post
    array<string> pre_list;
    array<string> post_list;
    for (uint i = 0; i < states_list.get_Length(); i++) {
        pre_list.Add(states_list[i].pre);
        post_list.Add(states_list[i].post);
    }

    export_dict.Set("states_list_pre", pre_list);
    export_dict.Set("states_list_post", post_list);

    // Should export as a file too maybe? Not sure
    log(toJson(export_dict));
}

void importStates(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    string cmdLinecpy = commandLine;
    // Obtain the text from the command line, and parse it as json
    if (cmdLinecpy.Split(" ").get_Length() <= 1) {
        log("No json provided");
        return;
    }
    array<string> relevant_strings = cmdLinecpy.Split(" ");
    relevant_strings.RemoveAt(0,1);

    // Join all the args into single stirng
    string json_string = Text::Join(relevant_strings, " ");
    log("Importing states from json: "+json_string);
    dictionary import_dict = parseJson(json_string);
    // set the variables
    int new_uid;
    int new_current_state;
    int new_states_tracker; 
    if (!import_dict.Get("uid", new_uid)) {
        log("Missing the UID!");
        return;
    }

    if (!import_dict.Get("current_state", new_current_state)) {
        log("Missing the current_state!");
        return;
    }

    if (!import_dict.Get("states_tracker", new_states_tracker)) {
        log("Missing the states tracker!");
        return;
    }

    array<string> pre_list;
    array<string> post_list;

    if (!import_dict.Get("states_list_pre", pre_list)) {
        log("Missing the pre_text list!");
        return;
    }

    if (!import_dict.Get("states_list_post", post_list)) {
        log("Missing the pre_text list!");
        return;
    }

    if (pre_list is null || post_list is null || pre_list.get_Length() != post_list.get_Length()) {
        log("Mismatch length of pre_list and post_list");
    }

    // All checks done, can finally assign.


    // Export current list before importing:
    print("Importing new states, here is old states export");
    exportStates(fromTime, toTime, commandLine, args);

    uid = new_uid;
    current_state = new_current_state;
    states_tracker = new_states_tracker;

    states_list.Clear();
    for (uint i = 0; i<pre_list.get_Length(); i++) {
        states_list.Add(StateStringStore(pre_list[i],post_list[i]));
    }

    log("Set the new uid: "+uid+", current_state: "+current_state+", states_tracker: "+states_tracker);
    printStateList();
}


void Main()
{
    RegisterCustomCommand("ussr_save_state", "Saves the state into a new file", saveState);
    RegisterCustomCommand("ussr_load_state", "Loads the \"Current State\"", loadState);
    RegisterCustomCommand("ussr_prev_state", "Sets the current state to one before, and loads it", prevState);
    RegisterCustomCommand("ussr_next_state", "Sets the current state to one after, and loads it", nextState);
    RegisterCustomCommand("ussr_reset_states", "Resets the tracking of states", resetStates);
    RegisterCustomCommand("ussr_export_states", "Export the current config into a json format and prints it", exportStates);
    RegisterCustomCommand("ussr_import_states", "Imports the json configuration exported by the export command", importStates);
    RegisterCustomCommand("ussr_log_states", "Same as export, but logs it in console", logStates);
    uid = Math::Rand(0, 2147483647);
    log("USSR started. UID: "+uid);


    // print("------------------");
    // // Testing json
    // string json_string = "{\"uid\": 67542869, \"current_state\": 0, \"states_tracker\": 1, \"states_list_pre\": [\"A01-Race_6.26_67542869\"], \"states_list_post\": [\"1-1_0\"]}";
    // print(toJson(parseJson(json_string)));
}

PluginInfo@ GetPluginInfo()
{
    auto info = PluginInfo();
    info.Name = "Undo Save States: Rollback (USSR)";
    info.Author = "TejasIsAmazing";
    info.Version = "v1.0.0";
    info.Description = "A button to undo to a previously saves state";
    return info;
}