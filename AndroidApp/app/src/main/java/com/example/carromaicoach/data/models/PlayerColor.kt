package com.example.carromaicoach.data.models

enum class PlayerColor {
    BLACK,
    WHITE;
    
    fun opposite(): PlayerColor {
        return if (this == BLACK) WHITE else BLACK
    }
}
