// Documentation available at https://donadigo.com/tminterface/plugins/api
// We will track the states by 01a, 02a, 03a, ...
// If we undo, and overwrite, we change to 01b, then 01c, and so on!
// continuing from there, it will go like, 01b.01, 01b.02, ...
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

int uid;



void printStateList() {
    string state_list_string = "[";

    for (uint i = 0; i < states_list.get_Length(); i++) {
        // Format each object however it is easiest for you to read
        state_list_string += "{" + states_list[i].pre + ", " + states_list[i].post + "}";
        
        // Add a comma between items, except for the last one
        if (i < states_list.get_Length() - 1) {
            state_list_string += ", ";
        }
    }
    state_list_string += "]";

    log("Statelist: "+ state_list_string);
}



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

    if (!(current_state == int(states_list.get_Length())-1)) {
        // If the current state is not at the end, we need to change the alt counting earlier, and remove the later stuff

        // Changing of letters
        // array = array[0:current+2]
        // I want this states list to have 
        states_list.Resize(current_state+2);
        string one_after_current_post = states_list[current_state+1].post;
        array<string> one_after_current_post_split = one_after_current_post.Split("_");

        string final_post_name;
        // The last one is always a pure integer
        if ((one_after_current_post_split[one_after_current_post_split.get_Length()-1]) == "0") {
            // Case of 1.2_3.4_5, 1.2_3.4_6.3_0
            // Change to 1.2_3.4_5, 1.2_3.4_6.4_0

            string iteration = one_after_current_post_split[one_after_current_post_split.get_Length()-2];
            // iteration is something like 6.3
            array<string> iterations = iteration.Split(".");
            string new_iteration = iterations[0]+"."+(Text::ParseInt(iterations[1])+1)+"_0";

            one_after_current_post_split.Resize(one_after_current_post_split.get_Length()-2);
            one_after_current_post_split.Add(new_iteration);
            final_post_name = Text::Join(one_after_current_post_split, "_");
        } else {
            // Case of 1.2_3.4_5, 1.2_3.4_6
            // Change to  1.2_3.4_5, 1.2_3.4_6.1_1
            string new_iteration = (one_after_current_post_split[one_after_current_post_split.get_Length()-1])+".1_0";

            one_after_current_post_split.Resize(one_after_current_post_split.get_Length()-1);
            one_after_current_post_split.Add(new_iteration);
            final_post_name = Text::Join(one_after_current_post_split, "_");
        }

        states_list[current_state+1] = StateStringStore(new_pre_name, final_post_name);
    } else {
        if (current_state == -1) {
            states_list.Add(StateStringStore(new_pre_name, "0"));
        } else {
            string current_post_name = states_list[current_state].post;
            array<string> post_names_data = current_post_name.Split("_");

            string new_post_post_name = ""+(Text::ParseInt(post_names_data[post_names_data.get_Length()-1])+1);
            post_names_data.RemoveAt(post_names_data.get_Length()-1, 1);
            
            post_names_data.Add(new_post_post_name);
            string new_post_name = Text::Join(post_names_data, "_");

            states_list.Add(StateStringStore(new_pre_name, new_post_name));
        }
    }
    current_state += 1;
    printStateList();
    log("Current: "+states_list[current_state].pre+"_"+states_list[current_state].post);

    if (!f.Save(states_list[current_state].pre+"_"+states_list[current_state].post+".bin", error)) {
        // Handle error
        log(error);
    }
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
void exportStates(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    
}

void importStates(int fromTime, int toTime, const string&in commandLine, const array<string>&in args) {
    
}


void Main()
{
    RegisterCustomCommand("ussr_save_state", "My command description", saveState);
    RegisterCustomCommand("ussr_load_state", "My command description", loadState);
    RegisterCustomCommand("ussr_prev_state", "My command description", prevState);
    RegisterCustomCommand("ussr_next_state", "My command description", nextState);
    RegisterCustomCommand("ussr_reset_states", "My command description", resetStates);
    RegisterCustomCommand("ussr_export_states", "My command description", exportStates);
    RegisterCustomCommand("ussr_import_states", "My command description", importStates);
    uid = Math::Rand(0, 2147483647);
    log("USSR started. UID: "+uid);
}

void OnDisabled()
{
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