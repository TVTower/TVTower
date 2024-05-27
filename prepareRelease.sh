#manual md->txt
cd docs
./Spielanleitung.CREATE.sh
cd ..

#disable dev keys for production
sed -i 's/DEV_KEYS value="TRUE"/DEV_KEYS value="FALSE"/' config/DEV.xml