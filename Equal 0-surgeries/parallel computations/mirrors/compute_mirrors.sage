

import multiprocessing
from pebble import ProcessPool
import sys

import os
import snappy
import csv

import signal
import time


###### Call back functions:
# callback function for the multiprocessing.
def std_callback(future): # call back
    try:
        result = future.result() # blocks until done.
    except TimeoutError as error:
        print("[INFO] Ended computation after {} seconds".format(error.args[1]))
    except Exception as error:
        print("Function raised {}".format(error))
        print(error.traceback)  # traceback of the function

########
        
def add_to_list(csv_file_path, row, columns, delimiter=","):
    """ Appends a row to the file."""

    with open(csv_file_path, "a", newline='') as file:
        writer = csv.DictWriter(file, fieldnames=columns, delimiter=delimiter)
        writer.writerow(row)



#
# Functions from the mirrors.ipynb
#

def all_positive(manifold):
    '''
    Checks if the solution type of a triangulation is positive.
    '''
    return manifold.solution_type() == 'all tetrahedra positively oriented'

def find_positive_triangulations(manifold,number=1,tries=100):
    '''
    Searches for one triangulation with a positive solution type.
    (Or if number is set to a different value also for different such triangulations.)
    '''
    M = manifold.copy()
    pos_triangulations=[]
    for i in range(tries):
        if all_positive(M):
            pos_triangulations.append(M)
            if len(pos_triangulations)==number:
                return pos_triangulations
            break
        M.randomize()
    for d in M.dual_curves(max_segments=500):
        X = M.drill(d)
        X = X.filled_triangulation()
        X.dehn_fill((1,0),-1)
        for i in range(tries):
            if all_positive(X):
                pos_triangulations.append(X)
                if len(pos_triangulations)==number:
                    return pos_triangulations
                break
            X.randomize()

    # In the closed case, here is another trick.
    if all(not c for c in M.cusp_info('is_complete')):
        for i in range(tries):
            # Drills out a random edge
            X = M.__class__(M.filled_triangulation())
            if all_positive(X):
                pos_triangulations.append(X)
                if len(pos_triangulations)==number:
                    return pos_triangulations
            break
            M.randomize()
    return pos_triangulations




### SYMMETRY GROUP

def better_symmetry_group(M,index=100):
    '''
    This function computes the symmetry group of the input manifold. 
    If the second entry is True it is proven to be the symmetry group.
    '''
    pos_triang=find_positive_triangulations(M,tries=index)
    if pos_triang==[]:
        full=False
        randomizeCount=0
        while randomizeCount<index and full==False:
            try:
                S=M.symmetry_group()
                full=S.is_full_group()
                M.randomize()
                randomizeCount=randomizeCount+1
            except (ValueError, RuntimeError, snappy.SnapPeaFatalError):
                M.randomize()
                randomizeCount=randomizeCount+1
        try:
            return (S,full)
        except NameError:
            return ('unclear',False)
    X=pos_triang[0]
    full=False
    randomizeCount=0
    while randomizeCount<index and full==False:
        try:
            S=X.symmetry_group()
            full=S.is_full_group()
            X.randomize()
            randomizeCount=randomizeCount+1
        except (ValueError, RuntimeError, snappy.SnapPeaFatalError):
            X.randomize()
            randomizeCount=randomizeCount+1
    if full==True:
        return (S,full)
    pos_triang=find_positive_triangulations(M,number=index,tries=index)
    if pos_triang==[]:
        try:
            return (S,full)
        except NameError:
            return ('unclear',False)
    for X in pos_triang:
        full=False
        randomizeCount=0
        while randomizeCount<index and full==False:
            try:
                S=X.symmetry_group()
                full=S.is_full_group()
                X.randomize()
                randomizeCount=randomizeCount+1
            except (ValueError, RuntimeError, snappy.SnapPeaFatalError):
                X.randomize()
                randomizeCount=randomizeCount+1
        if full==True:
            return (S,full)
    try:
        return (S,full)
    except NameError:
        return ('unclear',False)

#
# Check if knots are isomorphic
#
    
# TIMEOUT SIGNAL
def handle_timeout(signum, frame):
    raise TimeoutError


def check_if_zs_isotopic_to_mirror_list(knots, outfile, lock=None, worker_idx=-1, timeout=-1):
    """
    Processes a list of knots.
    """
    print("[WORKER #{}] Started work.".format(worker_idx)) 

    for idx, knot in enumerate(knots):
        if idx % 50 == 0:
            print("[WORKER #{}] Processed {} knots.".format(worker_idx, idx))
            sys.stdout.flush()

        # Set an alarm to trigger a timeout error
        if timeout > 0:
            signal.signal(signal.SIGALRM, handle_timeout)
            signal.alarm(timeout)

        try:
            check_if_zs_isotopic_to_mirror(knot, outfile, lock)
        except TimeoutError:
            # acquire the lock
            if lock != None:
                lock.acquire()
            add_to_list("timed_out_knots.csv", {"knot":knot}, columns=["knot"])
            # print("[WORKER #{}] Timeout after {} sec for knot {}".format(worker_idx, timeout, knot))
            # sys.stdout.flush()
            # release the lock
            if lock != None:
                lock.release()
        finally:
            # Cancel the alarm.
            signal.alarm(0) 
        

def check_if_zs_isotopic_to_mirror(knot, outfile, lock=None):
    """ Checks if the the zero-surgery (sz) has an orientation reversing symmetry.
    (I.e. the symmetry group is amphichiral.)
    
    Outputs the result to a file.

    The lock is used, so that no two processes write at the same time.
    """
    K=snappy.Manifold(knot)
    K.dehn_fill((0,1))
    [S,w]=better_symmetry_group(K,index=100) # w returns whether the symmetry group S is verified.
    amphichiral = None
    
      # Can directly print this. to a file: If w true, then S,w, S.amphichiral. || Else s,w,None
    # Test for 750: Then w=true aber nicht amphichiral.
    # Run in parallel.
    # Zeitlimit: 1min pro Knoten.
    if w==True:
        amphichiral = S.is_amphicheiral()

    # acquire the lock
    if lock != None:
        lock.acquire()

    result_row = {"knot":knot, "symmetry_group":S, "verified":w, "amphichiral":amphichiral}

    add_to_list(outfile, result_row, columns=["knot", "symmetry_group", "verified", "amphichiral"])
    # print("[INFO] Computed: {}".format(result_row))

    # release the lock
    if lock != None:
        lock.release()

def check_if_zs_isotopic_to_mirror_parallel(to_be_computed, outfile, num_workers, timeout):
    """
        Feeds a process pool with all the knots. Makes sure that its not too many processes as once,
        so to not bloat up the RAM.
    """
    start_time=time.time()
    
    with multiprocessing.Manager() as manager:
        lock = manager.Lock()
        with ProcessPool(max_workers=num_workers) as pool:
            
            chunk_size = int(len(to_be_computed) / num_workers) + 1
            for idx, start in enumerate(range(0, len(to_be_computed), chunk_size)):
                chunk = to_be_computed[start:start + chunk_size]

                # Then add to the pool
                future = pool.schedule(check_if_zs_isotopic_to_mirror_list, args=(chunk, outfile, lock, idx, timeout))
                future.add_done_callback(std_callback)
    
    print('[INFO] Finished.\n Total time taken: %s minutes ' % ((time.time() - start_time)/60)) 
    sys.stdout.flush()


if __name__ == "__main__":
    # File of knots to compute:
    csv_inpath = "../../vanishing_signature_hyp.csv"
    # File for outputs:
    csv_outpath = "results_sz_isotopic_to_mirror.csv"

    if not os.path.isfile(csv_outpath):
        # Create the heading if file doesn't exist yet.
        with open(csv_outpath, "w") as outfile:
            writer = csv.DictWriter(outfile, ["knot", "symmetry_group", "verified", "amphichiral"])
            writer.writeheader()

    # File for the timeouts:
    csv_timed_out = "timed_out_knots.csv"
    if not os.path.isfile(csv_outpath):
        # Create the heading if file doesn't exist yet.
        with open(csv_timed_out, "w") as outfile:
            writer = csv.DictWriter(outfile, ["knot"])
            writer.writeheader()


    # Num of parallel processes:
    num_workers = 32 ## Reduce this to the number of cores on the server.
    timeout = 60 # 60 sec  // See how things are going if just letting run one for each core.

    # load the knots from the file.
    print("[INFO] Loading the knots in question...")
    knots = []
    with open(csv_inpath, "r") as inputfile:
        reader = csv.DictReader(inputfile, fieldnames=["knot"])
        for row in reader:
            knots.append(row["knot"])

    # Computed so far:
    already_computed = []
    with open(csv_outpath, "r") as inputfile:
        reader = csv.DictReader(inputfile, fieldnames=["knot","symmetry_group","verified","amphichiral"])
        for row in reader:
            already_computed.append(row["knot"])

    # Timed out previously:
    timed_out = []
    with open(csv_timed_out, "r") as infile:
        reader = csv.DictReader(infile, ["knot"])
        for row in reader:
            timed_out.append(row["knot"])

    # Left to be computed
    left_to_be_computed = [k for k in knots if (k not in already_computed) and (k not in timed_out)]
    print("[INFO] {} knots left to be computed.".format(len(left_to_be_computed)))

    #####

    # start computation
    print("[INFO] Starting the computation.")
    sys.stdout.flush()
    check_if_zs_isotopic_to_mirror_parallel(left_to_be_computed, csv_outpath, num_workers, timeout)

    ####
    # Print number of knots timed out:
    timed_out = []
    with open(csv_timed_out, "r") as infile:
        reader = csv.DictReader(infile, ["knot"])
        for row in reader:
            timed_out.append(row["knot"])
    print("[INFO] Number of timed out (after {} sec) knots: {}".format(timeout, len(timed_out)))