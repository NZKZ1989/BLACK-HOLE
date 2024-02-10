#if defined _osblackhole_included
#endinput
#endif
#define _osblackhole_included

/*
Создаем Black Hole

iOwner - Индекс владельца
iTeam - Команда владельца
fPos - Позиция жертвы
*/
native void OS_BlackHole(int iOwner, int iTeam, float fPos[3]);
