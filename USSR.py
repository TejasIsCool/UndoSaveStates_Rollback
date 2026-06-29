# This is a file, used to test the naming of the savestates
# It does not really do anything functional, just a development aid
# You can delete this if you want if you have this downloaded for some reason


current = -1

# Stores both the pre names and post names!
# Will be array of structs instead
array: list[tuple[str,str]] = []


pre_name = "hii_2.3_1283891273_"

pseudo_counter = 0


post_name = "0"
while True:
    lorr = input("l or r or nr: ")

    if lorr == "nr":
        # First split the post_name, until we get the last section
        # Last section is always a number
        if current != len(array) - 1:
            # We want to include current, AND the one after it, which we will modify
            array = array[0:current+2]
            one_after_post = array[current+1][1]
            one_after_post_split = one_after_post.split("_")
            
            if int(one_after_post_split[-1]) == 0:
                # Case of 1.2_3.4_5, 1.2_3.4_6.3_0
                # Change to 1.2_3.4_5, 1.2_3.4_6.4_0
                iteration = one_after_post_split[-2]
                # iteration is something like 6.4 or smth
                iterations = iteration.split(".")
                new_iteration = iterations[0]+"."+str(int(iterations[1])+1)+"_0" 
                final_post_name = "_".join(one_after_post_split[0:-2]+[new_iteration])
                
            else:
                # Case of 1.2_3.4_5, 1.2_3.4_6
                # Change to  1.2_3.4_5, 1.2_3.4_6.1_1
                new_iteration = one_after_post_split[-1]+".1_0"
                final_post_name = "_".join(one_after_post_split[0:-1]+[new_iteration])
            
            array[current+1] = (array[current+1][0], final_post_name)
        else:
            
            if current == -1:
                array.append((pre_name, post_name))
            else:
                current_post_name = array[current][1]
                post_names_data = current_post_name.split("_")
                
                new_post_post_name =str(int(post_names_data[-1])+1)
                new_new_post_name = "_".join(post_names_data[0:-1]+[new_post_post_name])
                array.append((pre_name, new_new_post_name))
        current += 1


    if lorr == "l" and current >= 0:
        current -= 1
    
    if lorr == "r" and current < len(array) - 1:
        current += 1
    
    if current <= -1:
        print("BAD! OUT OF BOUNDS")
        continue
        
        
    print(array, f"Current: {array[current]}")