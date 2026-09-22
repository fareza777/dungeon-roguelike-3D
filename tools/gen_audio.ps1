$ErrorActionPreference = 'Continue'
$key = $env:ELEVENLABS_API_KEY
$out = "E:\Proyek Custom Game Kimi\game\assets\audio"
New-Item -ItemType Directory -Force "$out\vo", "$out\sfx", "$out\music" | Out-Null
$headers = @{ "xi-api-key" = $key; "Content-Type" = "application/json" }

$vos = @(
  "Di kedalaman bumi yang terlupakan, sebuah kerajaan tulang terbangun dari tidurnya.",
  "Kaulah prajurit terakhir yang berani menuruni tangga ini.",
  "Setiap lantai semakin gelap. Setiap langkah semakin berbahaya.",
  "Turunlah. Bertahanlah. Dan jangan pernah percaya kegelapan."
)
for ($i = 0; $i -lt $vos.Count; $i++) {
  $f = "$out\vo\line$($i+1).mp3"
  if (Test-Path $f) { Write-Host "VO $($i+1) SKIP (ada)"; continue }
  $body = @{ text = $vos[$i]; model_id = "eleven_multilingual_v2"; voice_settings = @{ stability = 0.55; similarity_boost = 0.75 } } | ConvertTo-Json
  try {
    Invoke-RestMethod -Uri "https://api.elevenlabs.io/v1/text-to-speech/pNInz6obpgDQGcFmaJgB" -Method Post -Headers $headers -Body $body -OutFile $f
    Write-Host "VO $($i+1) OK $((Get-Item $f).Length)"
  } catch { Write-Host "VO $($i+1) FAIL $($_.Exception.Message)" }
  Start-Sleep -Milliseconds 400
}

$sfx = @(
  @("swing", "sharp sword slash whoosh, fast, clean", 0.6),
  @("hit", "bone hit impact, crunchy crack, short", 0.5),
  @("death", "skeleton bones collapsing and clattering on stone floor", 1.2),
  @("levelup", "magical level up chime, bright fantasy sparkle", 1.5),
  @("click", "soft ui button click tap", 0.3),
  @("door", "heavy stone door grinding open, deep rumble", 2.0),
  @("hurt", "male hurt grunt, short, pained", 0.5),
  @("pickup", "item pickup sparkle, pleasant ding", 0.8)
)
foreach ($s in $sfx) {
  $f = "$out\sfx\$($s[0]).mp3"
  if (Test-Path $f) { Write-Host "SFX $($s[0]) SKIP (ada)"; continue }
  $body = @{ text = $s[1]; duration_seconds = [double]$s[2]; prompt_influence = 0.7 } | ConvertTo-Json
  try {
    Invoke-RestMethod -Uri "https://api.elevenlabs.io/v1/sound-effects" -Method Post -Headers $headers -Body $body -OutFile $f
    Write-Host "SFX $($s[0]) OK $((Get-Item $f).Length)"
  } catch { Write-Host "SFX $($s[0]) FAIL $($_.Exception.Message)" }
  Start-Sleep -Milliseconds 400
}

try {
  $mbody = @{ prompt = "dark dungeon ambient, ominous low strings, sparse deep drums, seamless loop, no vocals"; music_length_ms = 30000 } | ConvertTo-Json
  Invoke-RestMethod -Uri "https://api.elevenlabs.io/v1/music" -Method Post -Headers $headers -Body $mbody -OutFile "$out\music\dungeon.mp3"
  Write-Host "MUSIC OK $((Get-Item "$out\music\dungeon.mp3").Length)"
} catch { Write-Host "MUSIC FAIL $($_.Exception.Message)" }
Write-Host "AUDIO DONE"
