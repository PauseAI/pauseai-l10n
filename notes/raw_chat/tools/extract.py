import json
import sys
from pathlib import Path

def dump_conversation(json_path):
    out_path = Path(json_path).with_suffix('.txt')
    
    with open(json_path) as f:
        data = json.load(f)
    
    with open(out_path, 'w') as f:
        speakers = ["Anthony:", "Claude:"]
        speaker_idx = 0
        
        for msg in data['conversation']:
            text = msg.get('text', '').strip()
            if not text:
                continue
                
            f.write(f"\n{speakers[speaker_idx]}\n")
            f.write(text)
            f.write("\n\n" + "-"*8 + "\n")
            
            speaker_idx = (speaker_idx + 1) % 2

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 dump.py <json_file>")
        sys.exit(1)
        
    dump_conversation(sys.argv[1])
    print(f"Dumped to {Path(sys.argv[1]).with_suffix('.txt')}") 