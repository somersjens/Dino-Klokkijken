from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import shutil

root = Path('Documentation/Screenshots/ResultBotanicalFinish')
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 22)
labels = ['Jungle', 'Woestijn', 'Vulkaanland', 'Klokdorp', 'Kristalgrot', 'Klokstad', 'Slaapvallei', 'Tijdmachine', 'Tijdpiraten', 'Tijdkasteel']

for device in ['iphone', 'ipad']:
    folder = root / device
    folder.mkdir(parents=True, exist_ok=True)
    for world in range(1, 11):
        shutil.copy2(Path('/tmp/DinoScreenshots') / device / f'result-biome-world-{world}.png', folder / f'world-{world:02}.png')
    scene_width = 260 if device == 'iphone' else 300
    scene_height = 565 if device == 'iphone' else 405
    scenes = Image.new('RGB', ((scene_width+16)*5, (scene_height+48)*2), (246,242,231))
    details = Image.new('RGB', (5*360, 2*360), (246,242,231))
    sd, dd = ImageDraw.Draw(scenes), ImageDraw.Draw(details)
    for i, name in enumerate(labels):
        source = Image.open(folder / f'world-{i+1:02}.png').convert('RGB')
        x, y = (i%5)*(scene_width+16), (i//5)*(scene_height+48)
        sd.text((x+8,y+8),f'{i+1} · {name}',font=font,fill=(42,65,56))
        scene = source.copy(); scene.thumbnail((scene_width,scene_height))
        scenes.paste(scene,(x+8+(scene_width-scene.width)//2,y+40))
        top = .52 if device == 'iphone' else .47
        crop = source.crop((0,int(source.height*top),source.width,int(source.height*.82)))
        crop.thumbnail((344,305))
        dx,dy=(i%5)*360,(i//5)*360
        dd.text((dx+8,dy+8),f'{i+1} · {name}',font=font,fill=(42,65,56))
        details.paste(crop,(dx+(360-crop.width)//2,dy+42))
    scenes.save(root / f'werelden-{device}.jpg',quality=92)
    details.save(root / f'podiums-{device}.jpg',quality=94)

# A comparison of real app renders; source images are cropped and proportionally scaled only.
old = Image.open('Documentation/Screenshots/ResultNaturalLayers/review/world-01.png').convert('RGB')
new = Image.open(root / 'review/world-01.png').convert('RGB')
comparison = Image.new('RGB',(1240,405),(246,242,231)); cd=ImageDraw.Draw(comparison)
for x,label,im in [(0,'Voor · glad mos en losse blaadjes',old),(620,'Na · fijn mos en aangesloten bladranken',new)]:
    cd.text((x+12,12),label,font=font,fill=(42,65,56))
    crop=im.crop((0,int(im.height*.585),im.width,int(im.height*.85)))
    crop.thumbnail((600,345))
    comparison.paste(crop,(x+(620-crop.width)//2,49))
comparison.save(root/'mos-en-bladwerk-voor-na.jpg',quality=94)

rewards = root/'beloningen'; rewards.mkdir(exist_ok=True)
for i in range(4):
    source=Path('/tmp/DinoScreenshots/ipad')/f'result-redesign-{i}-stars.png'
    shutil.copy2(source,rewards/source.name)
print(root)
