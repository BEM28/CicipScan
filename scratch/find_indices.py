import subprocess

def find_indices():
    model_path = '/Volumes/Projects/BEM/2026/cicipscan/assets/models/1.tflite'
    targets = ["Lady Baltimore cake", "Lasagne", "Satay", "Nasi lemak", "Beef bourguignon", "Sushi"]
    
    process = subprocess.Popen(['strings', '-n', '3', model_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, _ = process.communicate()
    lines = stdout.decode('utf-8', errors='ignore').split('\n')
    
    start_idx = -1
    for i, line in enumerate(lines):
        if "Lady Baltimore cake" in line:
            start_idx = i
            break
            
    if start_idx == -1:
        print("Could not find start label.")
        return

    results = {}
    for target in targets:
        for i, line in enumerate(lines[start_idx:], start_idx):
            if target.lower() == line.strip().lower():
                # We need to account for MIDs and noise in the list
                # However, the previous extraction showed ~1992 unique labels.
                # Let's assume the order in 'all_labels.txt' I created earlier is correct.
                pass
    
    # Actually, let's just use the 'all_labels.txt' I created earlier
    with open('/Volumes/Projects/BEM/2026/cicipscan/scratch/labels_extracted.txt', 'r') as f:
        all_labels = [line.strip() for line in f.readlines()]
        
    for target in targets:
        for i, label in enumerate(all_labels):
            if target.lower() == label.lower():
                print(f"{i}: {label}")
                
find_indices()
