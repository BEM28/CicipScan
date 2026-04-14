import subprocess
import re

def extract():
    model_path = '/Volumes/Projects/BEM/2026/cicipscan/assets/models/1.tflite'
    try:
        # Run strings on the model
        process = subprocess.Popen(['strings', '-n', '3', model_path], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()
        lines = stdout.decode('utf-8', errors='ignore').split('\n')
        
        # We know labels start around "Lady Baltimore cake" and end around "Kondowole"
        labels = []
        capture = False
        for line in lines:
            line = line.strip()
            if "Lady Baltimore cake" in line:
                capture = True
            
            if capture:
                # Clean labels: 
                # 1. Remove MIDs (starts with /m/ or /g/)
                # 2. Remove PK markers
                # 3. Stop at the end of label block (probability-labels.txt)
                if "probability-labels" in line:
                    break
                
                clean_line = re.sub(r'PK$', '', line)
                if clean_line and not clean_line.startswith('/') and len(clean_line) > 1:
                    labels.append(clean_line)
                    
        # Remove duplicates while preserving order
        seen = set()
        unique_labels = [x for x in labels if not (x in seen or seen.add(x))]
        
        print(f"Extracted {len(unique_labels)} unique labels.")
        
        with open('/Volumes/Projects/BEM/2026/cicipscan/assets/models/labels.txt', 'w') as f:
            f.write('\n'.join(unique_labels))
            f.write('\n')
            
        print("Updated assets/models/labels.txt")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    extract()
