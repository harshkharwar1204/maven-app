package com.example.crudapp.repository;

import com.example.crudapp.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository // Marks this interface as a Spring repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    // JpaRepository provides methods like save(), findById(), findAll(), deleteById()
}