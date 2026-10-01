ruby -ryaml -e 'y=YAML.load_file(ARGV[0]); y["workflow"]["tasks"].each{|k,v| puts "#{k} <- #{v["predecessors"].inspect}"}' "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/30-preview-then-post-v7-1/30-preview-then-post-v7-1.workflow.yaml"
rg -n 'const DRY_RUN|const ALLOW_SAMPLE_POST|const USE_MAINTENANCE_TAG =' "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/30-preview-then-post-v7-1/30-preview-then-post-v7-1.workflow.yaml"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/30-preview-then-post-v7-1" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/30-preview-then-post-v7-1" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
